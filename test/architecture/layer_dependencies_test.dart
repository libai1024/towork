import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'source_rules.dart';

void main() {
  test(
    'dependency direction and mock composition boundaries stay enforced',
    () {
      final root = Directory.current.uri.resolve('lib/');
      final violations = <String>[];
      for (final file in Directory.fromUri(
        root,
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final source = file.uri.path.substring(root.path.length);
        for (final import in localDirectives(file.readAsStringSync())) {
          if (import.contains(':') && !import.startsWith('package:towork/')) {
            final problem = externalDependencyViolation(source, import);
            if (problem != null) violations.add('$source -> $import: $problem');
            continue;
          }
          final targetUri = import.startsWith('package:towork/')
              ? root.resolve(import.substring('package:towork/'.length))
              : file.uri.resolve(import);
          if (!targetUri.path.startsWith(root.path) ||
              !File.fromUri(targetUri).existsSync()) {
            violations.add(
              '$source -> $import: use an existing path inside lib',
            );
            continue;
          }
          final target = targetUri.path.substring(root.path.length);
          final problem = dependencyViolation(source, target);
          if (problem != null) violations.add('$source -> $target: $problem');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );

  test('guard rejects reverse, cross-feature and indirect re-export edges', () {
    for (final (source, target) in [
      ('app/a.dart', 'features/chat/page.dart'),
      ('app/a.dart', 'shell/router.dart'),
      ('features/chat/a.dart', 'features/todo/a.dart'),
      ('features/chat/barrel.dart', 'data/local/db.dart'),
      ('core/shared.dart', 'features/todo/page.dart'),
      ('domain/model.dart', 'shell/app.dart'),
      ('data/store.dart', 'shell/app.dart'),
      ('data/ai/gateway.dart', 'data/platform/consent.dart'),
      ('agent/decision.dart', 'data/local/store.dart'),
      ('domain/task.dart', 'agent/tools.dart'),
    ]) {
      expect(dependencyViolation(source, target), isNotNull);
    }
    expect(
      dependencyViolation('shell/router.dart', 'features/chat/page.dart'),
      isNull,
    );
    expect(
      dependencyViolation('features/chat/a.dart', 'features/chat/b.dart'),
      isNull,
    );
    expect(
      dependencyViolation('features/todo/a.dart', 'core/todo/item.dart'),
      isNull,
    );
  });

  test('domain and Agent cannot acquire host or persistence packages', () {
    for (final uri in [
      'dart:ui',
      'dart:io',
      'package:drift/drift.dart',
      'package:path_provider/path_provider.dart',
    ]) {
      expect(
        externalDependencyViolation('domain/workspace/new_rule.dart', uri),
        isNotNull,
      );
      expect(
        externalDependencyViolation('agent/new_planner.dart', uri),
        isNotNull,
      );
    }
    expect(
      externalDependencyViolation('domain/models/category.dart', 'dart:ui'),
      isNull,
    );
    expect(
      externalDependencyViolation(
        'domain/models/category.dart',
        'package:flutter/widgets.dart',
      ),
      isNotNull,
    );
  });

  test('guard reads both quote styles, exports and conditional branches', () {
    expect(
      localDirectives('''
// import 'ignored.dart';
/* export 'ignored_too.dart'; */
import 'a.dart' if (dart.library.io) "b.dart";
export "c.dart";
part 'd.dart';
part of app;
'''),
      ['a.dart', 'b.dart', 'c.dart', 'd.dart'],
    );
  });
}
