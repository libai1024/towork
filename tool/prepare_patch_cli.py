#!/usr/bin/env python3
"""Isolate the pinned CLI and stream unchanged large assets before patch limits.

The upstream 1.0.0+1 collector reads every asset through its 64 MiB patch-entry
limit before comparing hashes. ToWork's unchanged 228 MiB ASR model needs only
a streaming hash. Changed resources still pass through the original read limit,
native-asset rules, signing and runtime verification.
"""
import json
from pathlib import Path
import shutil
from urllib.parse import urljoin, urlparse, unquote

ROOT = Path(__file__).resolve().parents[1]
OLD = '''          final bytes = await read(variant);
          if ((baseline['files'] as Map)[variant]?['sha256'] !=
              sha256.convert(bytes).toString()) {'''
NEW = '''          assetKey(variant);
          final asset = p.join(bundle, variant);
          await rejectLinks(asset);
          if ((baseline['files'] as Map)[variant]?['sha256'] !=
              await hashFile(asset)) {'''


# Font-only packages have no lib/ directory. Preserve their package mapping
# while allowing an empty source copy; the compiler still checks all imports.
SOURCE_OLD = """    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {"""
SOURCE_NEW = """    final entries = await source.exists()
        ? source.list(recursive: true, followLinks: false)
        : const Stream<FileSystemEntity>.empty();
    await for (final entity in entries) {"""


def prepare():
    config_file = ROOT / '.dart_tool/package_config.json'
    config = json.loads(config_file.read_text())
    packages = config['packages']
    for package in packages:
        package['rootUri'] = urljoin(config_file.as_uri(), package['rootUri'])
    patcher = next(p for p in packages if p['name'] == 'flutter_patcher')
    source = Path(unquote(urlparse(patcher['rootUri']).path))
    assert 'version: 1.0.0+1\n' in (source / 'pubspec.yaml').read_text(), 'Review CLI adaptation after a plugin upgrade'
    output = ROOT / '.dart_tool/towork-code-cli'
    library = output / 'flutter_patcher'
    library.mkdir(parents=True, exist_ok=True)
    for name in ['lib', 'bin']:
        shutil.copytree(source / name, library / name, dirs_exist_ok=True)
    resources = library / 'lib/src/cli/patch/resources.dart'
    text = resources.read_text()
    assert text.count(OLD) == 1, 'Upstream asset collector changed'
    resources.write_text(text.replace(OLD, NEW))
    sources = library / 'lib/src/cli/patch/sources.dart'
    source_text = sources.read_text()
    assert source_text.count(SOURCE_OLD) == 1, 'Upstream source mapper changed'
    sources.write_text(source_text.replace(SOURCE_OLD, SOURCE_NEW))
    patcher['rootUri'] = library.as_uri() + '/'
    (output / 'package_config.json').write_text(json.dumps(config))
    return output


if __name__ == '__main__':
    print(prepare())
