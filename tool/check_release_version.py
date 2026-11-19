#!/usr/bin/env python3
"""Validate pubspec version and its optional release tag."""
from pathlib import Path
import re
import sys


def read_version(text):
    match = re.search(r'^version:\s*(\d+\.\d+\.\d+)\+([1-9]\d*)\s*$', text, re.M)
    if match is None:
        raise ValueError('pubspec requires version x.y.z+N with a positive build number')
    return match[1], int(match[2])


def validate_tag(tag, name, code):
    if tag != f'v{name}+{code}':
        raise ValueError(f'tag must equal v{name}+{code}')


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    name, code = read_version((root / 'pubspec.yaml').read_text())
    if len(sys.argv) > 1:
        validate_tag(sys.argv[1], name, code)
    print(f'{name}+{code}')
