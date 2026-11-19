#!/usr/bin/env python3
"""Regression for unchanged embedded ASR models in the isolated patch CLI."""
import os
from pathlib import Path
import subprocess

from prepare_patch_cli import prepare


def main():
    cli = prepare()
    test = cli / 'check_assets.dart'
    test.write_text(r'''
import 'dart:io';
import 'dart:convert';
import 'package:flutter_patcher/src/cli/core.dart';
import 'package:flutter_patcher/src/cli/patch/resources.dart';
import 'package:flutter_patcher/src/cli/patch/sources.dart';

Future<void> main() async {
  final temporary = await Directory.systemTemp.createTemp('towork-patch-assets-');
  final dir = Directory(await temporary.resolveSymbolicLinks());
  try {
    final model = File('${dir.path}/model.onnx');
    final stream = await model.open(mode: FileMode.write);
    await stream.truncate(65 * 1024 * 1024);
    await stream.close();
    final icon = File('${dir.path}/icon.txt');
    await icon.writeAsString('old');
    final manifest = {
      'model.onnx': [{'asset': 'model.onnx'}],
      'icon.txt': [{'asset': 'icon.txt'}],
    };
    await File('${dir.path}/AssetManifest.bin').writeAsBytes(AssetCodec.encode(manifest));
    final baseline = {
      'schema': 1, 'manifest': manifest,
      'files': {
        'model.onnx': {'sha256': await hashFile(model.path)},
        'icon.txt': {'sha256': await hashFile(icon.path)},
      },
    };
    PatchResources resources() => PatchResources(dir.path, dir.path, Commands(dir.path), dir.path);
    final unchanged = resources();
    await unchanged.collect(baseline, []);
    if (unchanged.assets.isNotEmpty) throw StateError('Unchanged assets were included');
    await icon.writeAsString('new');
    final changed = resources();
    await changed.collect(baseline, []);
    if (changed.assets.map((r) => r['key']).join(',') != 'icon.txt,AssetManifest.bin') {
      throw StateError('Changed small asset was lost');
    }
    final edit = await model.open(mode: FileMode.append);
    await edit.writeByte(1);
    await edit.close();
    var rejected = false;
    try { await resources().collect(baseline, []); }
    on Failure catch (error) { rejected = error.code == 'PATCH_ASSET_INVALID'; }
    if (!rejected) throw StateError('Changed oversized asset bypassed patch limit');
    final source = Directory('${dir.path}/source/lib');
    await source.create(recursive: true);
    await File('${source.path}/main.dart').writeAsString("import 'package:source/helper.dart';");
    final config = File('${dir.path}/packages.json');
    await config.writeAsString(jsonEncode({'configVersion': 2, 'packages': [
      {'name': 'source', 'rootUri': source.parent.uri.toString(), 'packageUri': 'lib/'},
      {'name': 'font_only', 'rootUri': '${dir.uri}font-only/', 'packageUri': 'lib/'},
    ]}));
    final output = '${dir.path}/module';
    final result = await remapSources(config.path, output, {'source', 'font_only'}, 3);
    final mapped = jsonDecode(await File(result['packages'] as String).readAsString()) as Map;
    if ((mapped['packages'] as List).length != 2 ||
        !await Directory('$output/font_only').exists() ||
        (await File('$output/source/main.dart').readAsString()) != "import 'package:patch.3.source/helper.dart';") {
      throw StateError('Asset-only dependency or Dart mapping was lost');
    }
    await Link('${source.path}/unsafe.dart').create('${source.path}/main.dart');
    var linkRejected = false;
    try { await remapSources(config.path, '${dir.path}/linked-module', {'source'}, 3); }
    on Failure catch (error) { linkRejected = error.code == 'PATCH_SOURCE_INVALID'; }
    if (!linkRejected) throw StateError('Symlink source validation was bypassed');
    stdout.writeln('Patch checks passed: unchanged large assets, changed assets, asset-only package, source remapping, symlink rejection.');
  } finally { await dir.delete(recursive: true); }
}
''')
    subprocess.run([os.environ.get('DART_BIN', 'dart'),
                    '--packages=' + str(cli / 'package_config.json'), str(test)], check=True)


if __name__ == '__main__':
    main()
