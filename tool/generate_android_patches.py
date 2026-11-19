#!/usr/bin/env python3
"""Generate and reconstruct exact signed APKs before adding delta metadata."""
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from hdiff_tools import binaries, digest


def generate(root, stage):
    manifest_file = stage / 'latest.json'
    release = json.loads(manifest_file.read_text())
    full = release['android']['full']
    target = stage / full['url']
    if digest(target) != full['sha256']:
        raise ValueError('Target APK checksum mismatch')
    candidates = []
    for previous_file in (root / 'build/releases').glob('*/latest.json'):
        previous = json.loads(previous_file.read_text())
        android = previous['android']
        previous_full = android['full']
        if (previous['versionCode'] >= release['versionCode'] or
                android['certSha256'] != release['android']['certSha256'] or
                android['abi'] != release['android']['abi']):
            continue
        if not re.fullmatch(r'android/towork-\d+\.\d+\.\d+-\d+-arm64\.apk', previous_full['url']):
            continue
        apk = previous_file.parent / previous_full['url']
        if apk.is_file() and apk.stat().st_size == previous_full['size'] and digest(apk) == previous_full['sha256']:
            candidates.append((previous['versionCode'], previous_full['sha256'], apk))
    candidates.sort(reverse=True)
    if not candidates:
        return
    hdiff, hpatch = binaries(root)
    patches = []
    for code, base_hash, base in candidates[:3]:
        name = f'towork-{code}-to-{release["versionCode"]}-{base_hash[:16]}-{full["sha256"][:16]}.hpatch'
        patch = stage / 'android' / name
        subprocess.run([str(hdiff), '-f', '-s-64', '-SD-2m', '-c-zlib', str(base), str(target), str(patch)], check=True)
        if patch.stat().st_size >= full['size']:
            patch.unlink()
            continue
        with tempfile.TemporaryDirectory(prefix='towork-patch-verify-') as temporary:
            rebuilt = Path(temporary) / 'rebuilt.apk'
            subprocess.run([str(hpatch), str(base), str(patch), str(rebuilt)], check=True)
            if rebuilt.stat().st_size != full['size'] or digest(rebuilt) != full['sha256']:
                raise ValueError('Reconstructed APK differs from signed target')
        patches.append({
            'format': 'hdiffpatch',
            'fromVersionCode': code,
            'fromSha256': base_hash,
            'url': 'android/' + name,
            'sha256': digest(patch),
            'size': patch.stat().st_size,
        })
        print(f'Verified delta {code} → {release["versionCode"]}: {patch.stat().st_size} bytes')
    release['android']['patches'] = patches
    manifest_file.write_text(json.dumps(release, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    generate(Path(__file__).resolve().parents[1], Path(sys.argv[1]))
