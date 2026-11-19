#!/usr/bin/env python3
"""Verify APK identity, version, entrypoint label, ABI and release build mode."""
from pathlib import Path
import re
import subprocess
import sys

from check_release_version import read_version


def verify_badging(text, name, code):
    package = re.search(r"^package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", text, re.M)
    if package is None or package.groups() != ('com.towork.towork', str(code), name):
        raise ValueError('APK identity/version differs from pubspec')
    if "application-label:'towork'" not in text:
        raise ValueError('APK must use the production lib/main.dart entrypoint')
    native = re.search(r'^native-code:\s*(.*)$', text, re.M)
    if native is None or native[1].strip() != "'arm64-v8a'":
        raise ValueError('Publish requires exactly the arm64-v8a ABI')
    if 'application-debuggable' in text:
        raise ValueError('Publish requires a release APK')


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    name, code = read_version((root / 'pubspec.yaml').read_text())
    badging = subprocess.check_output([sys.argv[1], 'dump', 'badging', sys.argv[2]], text=True)
    verify_badging(badging, name, code)
    print('APK identity, version, production entrypoint and arm64 ABI verified.')
