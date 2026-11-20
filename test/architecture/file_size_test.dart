import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'handwritten Dart files stay within 500 lines or their shrinking baseline',
    () {
      final baseline = (jsonDecode(
        File('test/architecture/file_size_baseline.json').readAsStringSync(),
      ) as Map<String, dynamic>).cast<String, int>();
      final violations = <String>[];
      final remaining = {...baseline};
      for (final file in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>()) {
        final path = file.path.replaceAll('\\', '/');
        if (!path.endsWith('.dart') ||
            path.endsWith('.g.dart') ||
            (path.startsWith('lib/l10n/generated/app_localizations') &&
                file.readAsStringSync().contains('class AppLocalizations'))) {
          continue;
        }
        final lines = file.readAsLinesSync().length;
        final limit = baseline[path] ?? 500;
        if (lines > limit) violations.add('$path: $lines > $limit');
        if (baseline.containsKey(path) && (lines != limit || lines <= 500)) {
          violations.add(
            '$path: reduce/remove its baseline to match $lines lines',
          );
        }
        remaining.remove(path);
      }
      for (final path in remaining.keys) {
        violations.add('$path: remove the obsolete baseline entry');
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );
}
