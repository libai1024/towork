#!/usr/bin/env python3
"""Verify and atomically promote a manifest while the caller holds flock."""
import hashlib
import json
from pathlib import Path
import re
import sys


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def promote(directory, staged_name):
    if not re.fullmatch(r'latest\.[a-f0-9]{64}\.json', staged_name):
        raise ValueError('Invalid staged manifest name')
    staged = directory / staged_name
    manifest = json.loads(staged.read_text())
    full = manifest['android']['full']
    if not re.fullmatch(r'[a-f0-9]{64}', full['sha256']):
        raise ValueError('Invalid APK hash')
    if staged_name != f'latest.{full["sha256"]}.json':
        raise ValueError('Manifest staging hash differs from APK hash')
    if type(manifest['versionCode']) is not int or manifest['versionCode'] <= 0:
        raise ValueError('Invalid version code')
    if not re.fullmatch(r'android/towork-\d+\.\d+\.\d+-\d+-arm64\.apk', full['url']):
        raise ValueError('Invalid APK path')
    apk = directory / full['url']
    staged_apk = directory / 'android' / f'.upload.{full["sha256"]}.apk'
    candidate = staged_apk if staged_apk.exists() else apk
    digest = sha256(candidate)
    if digest != full['sha256'] or candidate.stat().st_size != full['size']:
        raise ValueError('Uploaded APK size/hash differs from manifest')
    latest = directory / 'latest.json'
    if latest.exists():
        previous = json.loads(latest.read_text())
        if manifest['versionCode'] < previous['versionCode']:
            raise ValueError('A newer version is already published')
        if manifest['versionCode'] == previous['versionCode']:
            if digest != previous['android']['full']['sha256']:
                raise ValueError('The published version already has a different APK')
    artifacts = [(staged_apk, apk, digest)]
    patches = manifest['android'].get('patches', [])
    if not isinstance(patches, list) or len(patches) > 3:
        raise ValueError('Invalid patch list')
    for patch in patches:
        base = patch.get('fromSha256', '')
        patch_hash = patch.get('sha256', '')
        code = patch.get('fromVersionCode')
        size = patch.get('size')
        if (patch.get('format') != 'hdiffpatch' or
                not re.fullmatch(r'[a-f0-9]{64}', base) or
                not re.fullmatch(r'[a-f0-9]{64}', patch_hash) or
                type(code) is not int or not 0 < code < manifest['versionCode'] or
                type(size) is not int or not 0 < size < full['size']):
            raise ValueError('Invalid patch metadata')
        name = f'android/towork-{code}-to-{manifest["versionCode"]}-{base[:16]}-{digest[:16]}.hpatch'
        if patch.get('url') != name:
            raise ValueError('Invalid patch path')
        published_patch = directory / name
        uploaded_patch = directory / 'android' / f'.upload.{patch_hash}.hpatch'
        patch_candidate = uploaded_patch if uploaded_patch.exists() else published_patch
        if patch_candidate.stat().st_size != size or sha256(patch_candidate) != patch_hash:
            raise ValueError('Uploaded patch size/hash differs from manifest')
        artifacts.append((uploaded_patch, published_patch, patch_hash))
    # Validate every immutable destination before promoting any artifact.
    for uploaded, published, expected_hash in artifacts:
        if published.exists() and sha256(published) != expected_hash:
            raise ValueError('Immutable artifact filename already contains different bytes')
    for uploaded, published, _ in artifacts:
        if uploaded.exists():
            if published.exists():
                uploaded.unlink()
            else:
                uploaded.replace(published)
    # macOS releases independently and shares this manifest and publication lock.
    if latest.exists() and 'macos' in previous:
        manifest['macos'] = previous['macos']
        staged.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    staged.replace(latest)


if __name__ == '__main__':
    promote(Path.cwd(), sys.argv[1])
    print('Uploaded APK verified; latest.json promoted atomically.')
