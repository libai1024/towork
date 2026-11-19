import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authored app and website copy excludes decorative middle dots', () {
    final forbidden = RegExp(
      r'[\u00b7\u2022\u30fb\u2027\u2219]|\\u00b7|&middot;|&#0*183;|&#x0*b7;',
      caseSensitive: false,
    );
    final violations = <String>[];
    for (final root in ['lib', 'website']) {
      for (final file in Directory(
        root,
      ).listSync(recursive: true).whereType<File>()) {
        final path = file.path;
        if (path.endsWith('.g.dart') ||
            !['.dart', '.html', '.js', '.css'].any(path.endsWith)) {
          continue;
        }
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (forbidden.hasMatch(lines[i])) violations.add('$path:${i + 1}');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
