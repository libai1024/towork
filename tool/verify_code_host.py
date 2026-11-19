#!/usr/bin/env python3
"""Reject an ordinary Flutter APK from the code-update host release path."""
import json
import hashlib
from pathlib import Path
import sys
import zipfile

from check_release_version import read_version


def verify(apk, version_code):
    with zipfile.ZipFile(apk) as archive:
        trust = json.loads(archive.read('assets/flutter_patcher/host-trust.json'))
    policy = json.loads(trust['policy'])
    assert hashlib.sha256(trust['policy'].encode()).hexdigest() == trust['policy_sha256'], 'Invalid host policy hash'
    assert policy['application_id'] == 'com.towork.towork', 'Wrong code-update application'
    assert policy['version_code'] == str(version_code), 'Wrong code-update host version'
    assert policy['strategy'] == 'bytecode', 'Expected bytecode host'
    assert policy['root_key'] and policy['fptc_key'] and policy['keys'], 'Missing host trust keys'
    assert trust['url'] == 'https://zhaozhaoyue.top/dl/towork/patches', 'Wrong patch endpoint'
    assert len(trust['fingerprint']) == 64, 'Missing host fingerprint'


if __name__ == '__main__':
    _, code = read_version(Path('pubspec.yaml').read_text())
    verify(Path(sys.argv[1]), code)
    print('Code-update host trust verified.')
