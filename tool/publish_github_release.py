#!/usr/bin/env python3
"""Publish a tag's signed artifacts, preserving existing immutable assets."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from urllib.parse import quote

from check_release_version import read_version, validate_tag


def gh(*args):
    return subprocess.run(['gh', *args], text=True, capture_output=True, check=True)


def publish(tag, directory):
    files = sorted(path for path in directory.rglob('*') if path.is_file())
    if not any(path.suffix == '.apk' for path in files):
        raise ValueError('No APK in the release staging directory')
    try:
        release = json.loads(gh(
            'api', f'repos/{{owner}}/{{repo}}/releases/tags/{quote(tag, safe="")}',
        ).stdout)
    except subprocess.CalledProcessError:
        gh('release', 'create', tag, '--verify-tag', '--draft', '--generate-notes')
        release = {'draft': True, 'assets': []}
    existing = {asset['name']: asset for asset in release['assets']}
    for path in files:
        digest = 'sha256:' + hashlib.sha256(path.read_bytes()).hexdigest()
        asset = existing.get(path.name)
        if asset is not None:
            if asset.get('digest') != digest:
                raise ValueError(f'Published asset differs: {path.name}')
        elif release['draft']:
            gh('release', 'upload', tag, str(path))
        else:
            raise ValueError(f'Published release is missing {path.name}')
    if release['draft']:
        gh('release', 'edit', tag, '--draft=false')


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    name, code = read_version((root / 'pubspec.yaml').read_text())
    validate_tag(sys.argv[1], name, code)
    publish(sys.argv[1], root / 'build/releases' / f'{name}+{code}')
    print('GitHub release assets verified and published.')
