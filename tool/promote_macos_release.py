#!/usr/bin/env python3
"""Promote a staged DMG while the caller holds ToWork's .publish.lock."""
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile


def promote(directory, digest):
    if not re.fullmatch(r'[0-9a-f]{64}', digest):
        raise ValueError('Invalid DMG digest')
    folder = directory / 'macos'
    metadata = folder / f'.release.{digest}.json'
    info = json.loads(metadata.read_text())
    version, build = info['versionName'], info['versionCode']
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or type(build) is not int or build <= 0:
        raise ValueError('Invalid macOS version')
    name = f'towork-{version}-{build}-universal.dmg'
    if info['downloadUrl'] != 'macos/' + name or info['sha256'] != digest:
        raise ValueError('DMG metadata does not match filename and checksum')
    target = folder / name
    upload = folder / f'.upload.{digest}.dmg'
    candidate = target if target.exists() else upload
    checksum = hashlib.sha256()
    with candidate.open('rb') as src:
        for chunk in iter(lambda: src.read(1024 * 1024), b''):
            checksum.update(chunk)
    if candidate.stat().st_size != info['size'] or checksum.hexdigest() != digest:
        raise ValueError('DMG checksum or size differs')
    latest = directory / 'latest.json'
    manifest = json.loads(latest.read_text())
    previous = manifest.get('macos') or {}
    if previous.get('versionCode', 0) > build:
        raise ValueError('A newer macOS build is already published')
    if previous.get('versionCode') == build and previous.get('sha256') != digest:
        raise ValueError('A different DMG already exists for this build')
    manifest['macos'] = {**previous, **info}

    if not target.exists():
        upload.chmod(0o644)
        upload.replace(target)
    with tempfile.NamedTemporaryFile(mode='w', dir=directory, prefix='.macos-', delete=False) as tmp:
        temporary = Path(tmp.name)
        try:
            json.dump(manifest, tmp, ensure_ascii=False, indent=2)
            tmp.write('\n')
            tmp.flush()
            os.fsync(tmp.fileno())
            temporary.chmod(0o644)
            os.replace(temporary, latest)
        finally:
            temporary.unlink(missing_ok=True)
    metadata.unlink()
    upload.unlink(missing_ok=True)


if __name__ == '__main__':
    promote(Path.cwd(), sys.argv[1])
