import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/domain/workspace/workspace_queries.dart';
import 'package:towork/domain/workspace/workspace_validation.dart';

final now = DateTime.utc(2026, 9, 24);
WorkspaceEntity entity(
  String id,
  QueryObject patch, {
  WorkspaceEntityKind kind = WorkspaceEntityKind.todo,
  int version = 1,
  bool deleted = false,
}) => WorkspaceEntity(
  kind: kind,
  id: id,
  version: version,
  data: applyWorkspacePatch(kind, null, patch, now),
  createdAt: now,
  updatedAt: now.add(Duration(seconds: version)),
  deletedAt: deleted ? now : null,
);
WorkspaceEntity category(
  String id,
  String name, {
  String? parent,
  bool archived = false,
}) => entity(id, {
  'name': name,
  'parent_id': parent,
  'archived': archived,
}, kind: WorkspaceEntityKind.category);
List<String> ids(QueryObject result) =>
    (result['items']! as List).map((e) => (e as Map)['id']! as String).toList();
Matcher get invalid => throwsA(
  isA<WorkspaceFailure>().having(
    (e) => e.code,
    'code',
    WorkspaceFailureCode.validation,
  ),
);

void main() {
  test('AND filters use half-open UTC date range, active states, child categories and all tags', () {
    final snapshot = WorkspaceSnapshot([
      category('work', '工作'),
      category('team', '团队', parent: 'work'),
      entity('a', {
        'title': '周会',
        'category_id': 'team',
        'priority': 'high',
        'tags': ['会议', '准备'],
        'due_at': '2026-09-23T16:00:00Z',
      }),
      entity('b', {
        'title': '周会',
        'category_id': 'work',
        'priority': 'high',
        'tags': ['会议', '准备'],
        'status': 'inProgress',
        'due_at': '2026-09-24T15:59:59Z',
      }),
      entity('c', {
        'title': '周会',
        'category_id': 'work',
        'priority': 'high',
        'tags': ['会议', '准备'],
        'due_at': '2026-09-24T16:00:00Z',
      }),
      entity('d', {
        'title': '周会',
        'category_id': 'work',
        'priority': 'high',
        'tags': ['会议'],
        'due_at': '2026-09-24T01:00:00Z',
      }),
      entity('e', {
        'title': '周会',
        'category_id': 'work',
        'priority': 'high',
        'tags': ['会议', '准备'],
        'status': 'done',
        'due_at': '2026-09-24T01:00:00Z',
      }),
      entity('f', {
        'title': '周会',
        'category_id': 'work',
        'priority': 'high',
        'tags': ['会议', '准备'],
        'due_at': '2026-09-24T01:00:00Z',
      }, deleted: true),
    ]);
    final args = <String, Object?>{
      'query': ' 周会 ',
      'status': 'active',
      'category_id': 'work',
      'include_descendants': true,
      'priority': 'high',
      'tags': ['准备', '会议'],
      'due_from': '2026-09-23T16:00:00Z',
      'due_before': '2026-09-24T16:00:00Z',
    };
    expect(ids(WorkspaceQueries.todos(snapshot, args)), ['a', 'b']);
    expect(
      ids(
        WorkspaceQueries.todos(snapshot, {
          ...args,
          'include_descendants': false,
        }),
      ),
      ['b'],
    );
    expect(WorkspaceQueries.todos(snapshot, args)['matched_count'], 2);
    expect(
      WorkspaceQueries.todos(snapshot, args)['scope'],
      'materialized_records_only',
    );
  });

  test('explicit null category and no_due differ from omitted filters', () {
    final snapshot = WorkspaceSnapshot([
      category('work', '工作'),
      entity('a', {'title': '未分类', 'due_at': null}),
      entity('b', {'title': '有分类', 'category_id': 'work'}),
      entity('c', {'title': '有日期', 'due_at': '2026-09-24T00:00:00Z'}),
    ]);
    expect(ids(WorkspaceQueries.todos(snapshot, {})), ['a', 'b', 'c']);
    expect(
      ids(
        WorkspaceQueries.todos(snapshot, {'category_id': null, 'no_due': true}),
      ),
      ['a'],
    );
    expect(
      WorkspaceQueries.todos(snapshot, {'category_id': 'missing'})['error'],
      'category_not_found',
    );
  });

  test('sorted pages are deterministic with ties and null dates; tokens bind filter and snapshot', () {
    final snapshot = WorkspaceSnapshot([
      entity('a', {'title': 'same', 'priority': 'urgent'}),
      entity('b', {
        'title': 'same',
        'due_at': '2026-09-25T00:00:00Z',
        'priority': 'low',
      }),
      entity('c', {
        'title': 'same',
        'due_at': '2026-09-24T00:00:00Z',
        'priority': 'high',
      }),
      entity('d', {
        'title': 'same',
        'due_at': '2026-09-24T00:00:00Z',
        'priority': 'high',
      }),
    ]);
    const args = <String, Object?>{'order_by': 'due_at', 'limit': 2};
    final first = WorkspaceQueries.todos(snapshot, args);
    expect(ids(first), ['c', 'd']);
    expect(first['next_cursor'], isNull);
    final token = first['next_page_token'];
    expect(
      ids(WorkspaceQueries.todos(snapshot, {...args, 'page_token': token})),
      ['b', 'a'],
    );
    expect(
      ids(
        WorkspaceQueries.todos(snapshot, {
          'order_by': 'due_at',
          'direction': 'desc',
        }),
      ),
      ['b', 'c', 'd', 'a'],
    );
    expect(ids(WorkspaceQueries.todos(snapshot, {'order_by': 'priority'})), [
      'a',
      'c',
      'd',
      'b',
    ]);
    expect(
      ids(
        WorkspaceQueries.todos(snapshot, {
          'order_by': 'id',
          'direction': 'desc',
        }),
      ),
      ['d', 'c', 'b', 'a'],
    );
    expect(
      WorkspaceQueries.todos(snapshot, {
        ...args,
        'query': 'same',
        'page_token': token,
      })['error'],
      'cursor_stale',
    );
    final changed = WorkspaceSnapshot([
      for (final row in snapshot.todos)
        if (row.id != 'b') row,
      entity('b', {
        'title': 'edited',
        'due_at': '2026-09-25T00:00:00Z',
      }, version: 2),
    ]);
    expect(
      WorkspaceQueries.todos(changed, {...args, 'page_token': token})['error'],
      'cursor_stale',
    );
    // Page size can change without changing the query identity.
    expect(
      ids(
        WorkspaceQueries.todos(snapshot, {
          ...args,
          'limit': 1,
          'page_token': token,
        }),
      ),
      ['b'],
    );
  });

  test('Unicode result size limit paginates actual returned IDs without dropping matches', () {
    final snapshot = WorkspaceSnapshot([
      for (var i = 0; i < 30; i++)
        entity('t${i.toString().padLeft(2, '0')}', {
          'title': '待办$i',
          'note': '中' * 4000,
          'tags': [for (var j = 0; j < 30; j++) '标签$j'],
        }),
    ]);
    String? token;
    final seen = <String>[];
    do {
      final result = WorkspaceQueries.todos(snapshot, {
        'limit': 50,
        'page_token': ?token,
      });
      expect(
        utf8.encode(jsonEncode(result)).length,
        lessThanOrEqualTo(WorkspaceQueries.pageBytes),
      );
      final page = ids(result);
      expect(page, isNotEmpty);
      seen.addAll(page);
      final item = (result['items']! as List).first as Map;
      expect(item['note_truncated'], isTrue);
      expect(item['tags_truncated'], isTrue);
      token = result['next_page_token'] as String?;
    } while (token != null);
    expect(seen, hasLength(30));
    expect(seen.toSet(), hasLength(30));
  });

  test('detail reads complete Unicode note segments and guards against version changes', () {
    final note = '备忘🙂' * 900;
    final snapshot = WorkspaceSnapshot([
      entity('a', {
        'title': '详情',
        'note': note,
        'source': 'ai',
        'source_message_id': 'msg1',
        'remind_rules': [
          {'id': 'r1', 'offset_minutes': -5},
        ],
        'tags': [for (var i = 0; i < 30; i++) 'tag$i'],
      }),
    ]);
    var offset = 0;
    final joined = StringBuffer();
    while (true) {
      final result = WorkspaceQueries.todo(snapshot, {
        'id': 'a',
        'expected_version': 1,
        'note_offset': offset,
        'note_limit': 701,
      });
      expect(result['source_message_id'], 'msg1');
      expect(result['remind_rules'], hasLength(1));
      expect(result['tags'], hasLength(30));
      expect(result['tags_truncated'], isFalse);
      joined.write(result['note_segment']);
      if (result['next_note_offset'] == null) break;
      offset = result['next_note_offset']! as int;
    }
    expect(joined.toString(), note);
    expect(
      WorkspaceQueries.todo(snapshot, {
        'id': 'a',
        'expected_version': 2,
      })['error'],
      'version_changed',
    );
    expect(
      WorkspaceQueries.todo(snapshot, {'id': 'missing'})['error'],
      'not_found',
    );
    expect(
      () => WorkspaceQueries.todo(snapshot, {'id': 'a', 'note_offset': 1}),
      invalid,
    );
    expect(
      () => WorkspaceQueries.todo(snapshot, {
        'id': 'a',
        'expected_version': 1,
        'note_offset': 9000,
      }),
      invalid,
    );
  });

  test('category lookup retains duplicate names with parents and excludes archived defaults', () {
    final snapshot = WorkspaceSnapshot([
      category('a', '工作'),
      category('b', '个人'),
      category('c', '读书', parent: 'a'),
      category('d', '读书', parent: 'b'),
      category('e', '读书', archived: true),
    ]);
    final matching = WorkspaceQueries.categories(snapshot, {'query': '读书'});
    expect(ids(matching), ['c', 'd']);
    expect((matching['items']! as List).map((e) => (e as Map)['parent_name']), [
      '工作',
      '个人',
    ]);
    expect(ids(WorkspaceQueries.categories(snapshot, {'parent_id': null})), [
      'a',
      'b',
    ]);
    expect(ids(WorkspaceQueries.categories(snapshot, {'parent_id': 'a'})), [
      'c',
    ]);
    expect(
      ids(
        WorkspaceQueries.categories(snapshot, {
          'query': '读书',
          'include_archived': true,
          'after_id': 'd',
        }),
      ),
      ['e'],
    );
  });

  test('unknown fields, injection, invalid dates, contradictory filters and malformed cursors reject', () {
    final snapshot = WorkspaceSnapshot([
      entity('a', {'title': 'unchanged'}),
    ]);
    for (final args in <QueryObject>[
      {'sql': 'DROP TABLE work_todos'},
      {'order_by': 'title; DROP TABLE'},
      {'due_from': '2026-02-30T00:00:00Z'},
      {'due_from': '2026-09-24'},
      {'due_from': '2026-09-24T00:00:00+08:00'},
      {
        'due_from': '2026-09-25T00:00:00Z',
        'due_before': '2026-09-24T00:00:00Z',
      },
      {'no_due': true, 'due_before': '2026-09-24T00:00:00Z'},
      {
        'tags': [1],
      },
      {
        'tags': [' '],
      },
      {'category_id': 1},
      {'include_descendants': true},
      {'status': 'everything'},
      {'limit': 51},
      {'page_token': 'invalid'},
      {'category_id': 'missing', 'page_token': 'invalid'},
      {'after_id': 'a', 'order_by': 'priority'},
    ]) {
      expect(
        () => WorkspaceQueries.todos(snapshot, args),
        invalid,
        reason: '$args',
      );
    }
    expect(
      ids(WorkspaceQueries.todos(snapshot, {'query': "' OR 1=1 --"})),
      isEmpty,
    );
    expect(snapshot.todos.single.data['title'], 'unchanged');
  });
}
