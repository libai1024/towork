#!/usr/bin/env python3
"""Reject increases or new exemptions in the handwritten Dart size baseline."""
import argparse
import json
from pathlib import Path
import subprocess

BASELINE = 'test/architecture/file_size_baseline.json'


def violations(previous, current, renames=None):
    renames = renames or {}
    errors = []
    for path, limit in current.items():
        old_path = renames.get(path, path)
        old_limit = previous.get(old_path)
        if old_limit is None or limit > old_limit:
            errors.append(f'{path}: baseline increased from {old_limit} to {limit}')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', default='HEAD')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    base = args.base
    if not base or set(base) == {'0'}:
        base = 'HEAD^'
    subprocess.run(['git', 'rev-parse', '--verify', f'{base}^{{commit}}'],
                   cwd=root, check=True, stdout=subprocess.DEVNULL)
    prior = subprocess.run(['git', 'show', f'{base}:{BASELINE}'], cwd=root,
                           capture_output=True, text=True)
    if prior.returncode:
        print('First file-size baseline on this history.')
        return
    changes = subprocess.check_output(
        ['git', 'diff', '--name-status', '-M', base, '--', 'lib'],
        cwd=root, text=True,
    )
    renames = {}
    for line in changes.splitlines():
        fields = line.split('\t')
        if fields[0].startswith('R') and len(fields) == 3:
            renames[fields[2]] = fields[1]
    errors = violations(json.loads(prior.stdout),
                        json.loads((root / BASELINE).read_text()), renames)
    if errors:
        raise SystemExit('\n'.join(errors))
    print('File-size baseline only shrinks.')


if __name__ == '__main__':
    main()
