import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/models/models.dart';

final now = DateTime.utc(2026, 9, 23, 12);

Todo task({List<String> tags = const [], List<RemindRule> rules = const []}) =>
    Todo(
      id: 'task',
      title: '交报告',
      createdAt: now,
      tags: tags,
      remindRules: rules,
      note: '原备注',
      dueAt: now,
      remindAt: now,
      repeatRule: 'FREQ=DAILY',
      categoryId: 'work',
      sourceMessageId: 'message',
      updatedAt: now,
      completedAt: now,
    );

MemoryEntry memory({
  DateTime? expiry,
  List<String> categoryIds = const [],
  double confidence = 1,
}) => MemoryEntry(
  id: 'memory',
  content: '偏好简洁回复',
  type: MemoryType.preference,
  createdAt: now,
  updatedAt: now,
  expiresAt: expiry,
  categoryIds: categoryIds,
  sourceSessionId: 'session',
  sourceSessionTitle: '工作记录',
  confidence: confidence,
);

Report report({
  List<ReportCategoryRef> categories = const [],
  List<String> incomplete = const [],
}) => Report(
  id: 'report',
  type: ReportType.weekly,
  title: '本周',
  periodLabel: '本周',
  summary: '摘要',
  createdAt: now,
  periodStart: now,
  periodEnd: now,
  categorySnapshot: categories,
  incompleteSections: incomplete,
  failureReason: 'network',
  model: 'k3',
  generatedAt: now,
  deletedAt: now,
);

void main() {
  group('nullable copyWith fields', () {
    test('Todo distinguishes omission, replacement and explicit clearing', () {
      final original = task();
      final kept = original.copyWith(title: '新标题');
      expect(kept.note, '原备注');
      expect(kept.dueAt, now);
      expect(kept.sourceMessageId, 'message');
      final cleared = original.copyWith(
        note: null,
        dueAt: null,
        remindAt: null,
        repeatRule: null,
        categoryId: null,
        sourceMessageId: null,
        updatedAt: null,
        completedAt: null,
      );
      expect([
        cleared.note,
        cleared.dueAt,
        cleared.remindAt,
        cleared.repeatRule,
        cleared.categoryId,
        cleared.sourceMessageId,
        cleared.updatedAt,
        cleared.completedAt,
      ], everyElement(isNull));
      expect(original.note, '原备注');
      expect(original.copyWith(note: '新备注').note, '新备注');
    });

    test('Category parent can be retained, reassigned or removed', () {
      const original = Category(
        id: 'child',
        name: '子分类',
        color: Color(0xFF1783FF),
        parentId: 'parent',
      );
      expect(original.copyWith(name: '新名').parentId, 'parent');
      expect(original.copyWith(parentId: 'new').parentId, 'new');
      expect(original.copyWith(parentId: null).parentId, isNull);
    });

    test(
      'Memory supports explicit null with legacy clearExpiry compatibility',
      () {
        final original = memory(expiry: now.add(const Duration(days: 1)));
        expect(original.copyWith(content: '更新').expiresAt, original.expiresAt);
        expect(original.copyWith(expiresAt: null).expiresAt, isNull);
        expect(original.copyWith(clearExpiry: true).expiresAt, isNull);
        expect(
          original.copyWith(clearExpiry: true, expiresAt: now).expiresAt,
          isNull,
        );
        final detached = original.copyWith(
          sourceSessionId: null,
          sourceSessionTitle: null,
        );
        expect(detached.sourceSessionId, isNull);
        expect(detached.sourceSessionTitle, isNull);
        expect(original.copyWith(expiresAt: now).expiresAt, now);
      },
    );

    test(
      'Message metadata can be cleared while immutable identity is retained',
      () {
        final original = ChatMessage(
          id: 'm',
          sessionId: 's',
          role: ChatRole.assistant,
          type: ChatMessageType.todoCard,
          content: '已创建',
          createdAt: now,
          todoId: 't',
          modelId: 'k3',
          durationMs: 50,
        );
        expect(original.copyWith(content: '保留').todoId, 't');
        final cleared = original.copyWith(
          type: ChatMessageType.text,
          todoId: null,
          modelId: null,
          durationMs: null,
        );
        expect([
          cleared.todoId,
          cleared.modelId,
          cleared.durationMs,
        ], everyElement(isNull));
        expect(cleared.id, original.id);
        expect(cleared.type, ChatMessageType.text);
      },
    );

    test('Report null metadata and column unit follow the same contract', () {
      final original = report();
      expect(original.copyWith(title: '新标题').model, 'k3');
      final cleared = original.copyWith(
        failureReason: null,
        model: null,
        generatedAt: null,
        deletedAt: null,
      );
      expect([
        cleared.failureReason,
        cleared.model,
        cleared.generatedAt,
        cleared.deletedAt,
      ], everyElement(isNull));
      final column = DataColumnDef(name: '数量', type: 'number', unit: '份');
      expect(column.copyWith(name: '计数').unit, '份');
      expect(column.copyWith(unit: null).unit, isNull);
    });
  });

  group('immutable model snapshots', () {
    test('Todo and Memory own their collection inputs and copies', () {
      final tags = ['urgent'];
      final rules = [const RemindRule(id: 'r', offsetMinutes: 30)];
      final categories = ['work'];
      final original = task(tags: tags, rules: rules);
      final entry = memory(categoryIds: categories);
      tags.add('changed');
      rules.clear();
      categories.clear();
      expect(original.tags, ['urgent']);
      expect(original.remindRules, hasLength(1));
      expect(entry.categoryIds, ['work']);
      expect(() => original.tags.add('x'), throwsUnsupportedError);
      expect(() => original.remindRules.clear(), throwsUnsupportedError);
      expect(() => entry.categoryIds.clear(), throwsUnsupportedError);
      final replacements = ['new'];
      final copied = original.copyWith(tags: replacements);
      replacements.clear();
      expect(copied.tags, ['new']);
    });

    test('historical Report snapshots cannot be changed by callers', () {
      final categories = [
        const ReportCategoryRef(
          id: 'work',
          name: '工作',
          color: Color(0xFF1783FF),
        ),
      ];
      final incomplete = ['工作'];
      final original = report(categories: categories, incomplete: incomplete);
      final copied = original.copyWith(title: '更新');
      categories.clear();
      incomplete.clear();
      expect(original.categorySnapshot.single.name, '工作');
      expect(copied.incompleteSections, ['工作']);
      expect(() => copied.categorySnapshot.clear(), throwsUnsupportedError);
      expect(() => copied.incompleteSections.clear(), throwsUnsupportedError);
    });

    test('tables, columns and template row maps are frozen at every layer', () {
      final choices = ['公开'];
      final column = DataColumnDef(
        name: '密级',
        type: 'enum',
        enumOptions: choices,
      );
      final columns = [column];
      final seedRow = {'密级': '公开'};
      final seedRows = [seedRow];
      final table = DataTableDef(
        id: 'table',
        name: '档案',
        columns: columns,
        createdAt: now,
      );
      final template = DataTableTemplate(
        id: 'tpl',
        name: '档案',
        iconKey: 'folder',
        description: '',
        columns: columns,
        seedRows: seedRows,
      );
      choices.clear();
      columns.clear();
      seedRow['密级'] = '机密';
      seedRows.clear();
      expect(table.columns.single.enumOptions, ['公开']);
      expect(template.columns.single.enumOptions, ['公开']);
      expect(template.seedRows.single, {'密级': '公开'});
      expect(() => table.columns.clear(), throwsUnsupportedError);
      expect(() => column.enumOptions.clear(), throwsUnsupportedError);
      expect(() => template.seedRows.clear(), throwsUnsupportedError);
      expect(
        () => template.seedRows.single['密级'] = '内部',
        throwsUnsupportedError,
      );
    });

    test('row values and audit snapshots are detached and read-only', () {
      final before = {'价格': '100'};
      final after = {'价格': '110'};
      final row = DataRow(
        id: 'r',
        tableId: 't',
        values: before,
        updatedAt: now,
      );
      final log = DataChangeLog(
        id: 'log',
        tableId: 't',
        rowId: 'r',
        field: '价格',
        oldValue: '100',
        newValue: '110',
        source: DataChangeSource.manual,
        createdAt: now,
        beforeValues: before,
        afterValues: after,
      );
      before.clear();
      after.clear();
      expect(row.values, {'价格': '100'});
      expect(log.beforeValues, {'价格': '100'});
      expect(log.afterValues, {'价格': '110'});
      expect(() => row.values.clear(), throwsUnsupportedError);
      expect(() => log.beforeValues!.clear(), throwsUnsupportedError);
      expect(() => log.afterValues!.clear(), throwsUnsupportedError);
      final replacement = {'价格': '120'};
      final copied = row.copyWith(values: replacement);
      replacement.clear();
      expect(copied.values, {'价格': '120'});
    });

    test(
      'pending AI change batches are stable while awaiting confirmation',
      () {
        final fields = [
          const PendingFieldChange(
            field: '价格',
            oldValue: '100',
            newValue: '110',
          ),
        ];
        final values = {'价格': '110'};
        final change = PendingRowChange(
          id: 'change',
          action: DataChangeAction.create,
          rowLabel: '新行',
          fields: fields,
          createValues: values,
        );
        final changes = [change];
        final batch = PendingAiBatch(
          id: 'batch',
          tableId: 't',
          reason: '更新',
          sourceLabel: '截图',
          createdAt: now,
          changes: changes,
        );
        fields.clear();
        values.clear();
        changes.clear();
        expect(batch.changes.single.fields.single.newValue, '110');
        expect(batch.changes.single.createValues, {'价格': '110'});
        expect(() => batch.changes.clear(), throwsUnsupportedError);
        expect(() => change.fields.clear(), throwsUnsupportedError);
        expect(() => change.createValues.clear(), throwsUnsupportedError);
      },
    );

    test('QuotaState keeps an immutable usage snapshot', () {
      final bars = [
        const QuotaBar(
          label: '本周',
          usedTokens: 40,
          limitTokens: 100,
          resetNote: '',
        ),
      ];
      final state = QuotaState(bars: bars);
      bars.clear();
      expect(state.bars.single.percent, 40);
      expect(() => state.bars.clear(), throwsUnsupportedError);
    });
  });

  group('calendar and data boundaries', () {
    test('ISO week numbers handle cross-year dates and leap years', () {
      final examples = <DateTime, int>{
        DateTime.utc(2015, 12, 31): 53,
        DateTime.utc(2016, 1, 1): 53,
        DateTime.utc(2016, 1, 3): 53,
        DateTime.utc(2016, 1, 4): 1,
        DateTime.utc(2018, 12, 31): 1,
        DateTime.utc(2020, 2, 29): 9,
        DateTime.utc(2020, 12, 31): 53,
        DateTime.utc(2021, 1, 1): 53,
        DateTime.utc(2021, 1, 4): 1,
        DateTime.utc(2024, 2, 29): 9,
        DateTime.utc(2024, 12, 30): 1,
      };
      for (final example in examples.entries) {
        expect(
          isoWeekNumber(example.key),
          example.value,
          reason: example.key.toIso8601String(),
        );
        expect(
          isoWeekNumber(
            DateTime(
              example.key.year,
              example.key.month,
              example.key.day,
              23,
              59,
            ),
          ),
          example.value,
        );
      }
    });

    test('Memory expiry uses an exact seven-day boundary', () {
      expect(memory(expiry: now).isExpired(now), isTrue);
      expect(memory(expiry: now).isExpiringSoon(now), isFalse);
      expect(
        memory(expiry: now.add(const Duration(days: 7))).isExpiringSoon(now),
        isTrue,
      );
      expect(
        memory(expiry: now.add(const Duration(days: 7, microseconds: 1)))
            .isExpiringSoon(now),
        isFalse,
      );
      expect(memory().isExpired(now), isFalse);
      expect(memory().isExpiringSoon(now), isFalse);
    });

    test(
      'known field names and currency alias remain accepted, unknown rejects',
      () {
        final expected = {
          'text': DataFieldType.text,
          'number': DataFieldType.number,
          'money': DataFieldType.money,
          'currency': DataFieldType.money,
          'date': DataFieldType.date,
          'datetime': DataFieldType.datetime,
          'enum': DataFieldType.selection,
          'bool': DataFieldType.boolean,
        };
        for (final entry in expected.entries) {
          expect(
            DataColumnDef(name: '字段', type: entry.key).fieldType,
            entry.value,
          );
        }
        expect(
          () => DataColumnDef(name: '字段', type: 'typo'),
          throwsFormatException,
        );
      },
    );

    test('confidence rejects invalid finite and non-finite values', () {
      for (final confidence in [-.01, 1.01, double.nan, double.infinity]) {
        expect(() => memory(confidence: confidence), throwsArgumentError);
      }
      expect(memory(confidence: 0).isLowConfidence, isTrue);
      expect(memory(confidence: 1).confidenceLabel, '高');
    });

    test('reminder must select exactly one time representation', () {
      expect(() => RemindRule(id: 'invalid'), throwsAssertionError);
      expect(
        () => RemindRule(id: 'invalid', offsetMinutes: 0, absoluteAt: now),
        throwsAssertionError,
      );
      expect(
        const RemindRule(id: 'relative', offsetMinutes: 0).offsetMinutes,
        0,
      );
      expect(RemindRule(id: 'absolute', absoluteAt: now).absoluteAt, now);
    });
  });
}
