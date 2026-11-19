import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_tool_registry.dart';
import 'package:towork/agent/tools/todo_panel_tool.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/chat/todo_panel.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

final now = DateTime.utc(2026, 11, 16, 17); // Tuesday 01:00, UTC+8.
WorkspaceEntity todo(
  String id, {
  String? due,
  String status = 'pending',
  String priority = 'none',
  String? category,
  bool deleted = false,
}) => WorkspaceEntity(
  kind: WorkspaceEntityKind.todo,
  id: id,
  version: 1,
  createdAt: now,
  updatedAt: now,
  deletedAt: deleted ? now : null,
  data: {
    'title': id,
    'status': status,
    'priority': priority,
    'tags': <String>[],
    'due_at': due,
    'category_id': category,
  },
);

void main() {
  final context = AgentToolContext(
    now: now,
    localOffset: const Duration(hours: 8),
    snapshot: WorkspaceSnapshot([
      todo('yesterday', due: '2026-11-16T15:59:59Z'),
      todo('midnight', due: '2026-11-16T16:00:00Z'),
      todo('later', due: '2026-11-17T10:00:00Z', priority: 'urgent'),
      todo('tomorrow', due: '2026-11-17T16:00:00Z'),
      todo('sunday', due: '2026-11-22T15:59:59Z'),
      todo('next-week', due: '2026-11-22T16:00:00Z'),
      todo('finished', due: '2026-11-17T10:00:00Z', status: 'done'),
      todo('cancelled', priority: 'urgent', status: 'cancelled'),
      todo('removed', priority: 'urgent', deleted: true),
      todo('working', status: 'inProgress'),
      todo('high', priority: 'high'),
    ]),
  );
  Map<String, Object?> run(
    Map<String, Object?> args, {
    bool overview = false,
  }) =>
      TodoPanelTool(overview: overview).call(args, context)!
          as Map<String, Object?>;
  List<String> ids(String scope) => TodoPanel.decode(
    run({'title': '清单', 'scope': scope})['ui'],
    overview: false,
  )!.sections.single.todoIds;

  test('scope boundaries use local day and Monday-Sunday week', () {
    expect(ids('today'), ['midnight', 'later']);
    expect(ids('overdue'), ['yesterday', 'midnight']);
    expect(ids('week'), [
      'yesterday',
      'midnight',
      'later',
      'tomorrow',
      'sunday',
    ]);
    expect(ids('urgent'), ['later']);
    expect(ids('in_progress'), ['working']);
    expect(ids('undated'), ['high', 'working']);
    expect(ids('all'), isNot(contains('finished')));
    expect(context.snapshot.todos.length, 10);
  });

  test(
    'overview and bounded list preserve exact total and localized details',
    () {
      final list = run({'title': '今日待办', 'scope': 'today', 'limit': 1});
      final panel = TodoPanel.decode(list['ui'], overview: false)!;
      expect(panel.asOfLocal, '2026-11-17T01:00+08:00');
      expect(panel.sections.single.matchedCount, 2);
      expect(panel.sections.single.todoIds, ['midnight']);
      expect(
        (((list['sections'] as List).single as Map)['items'] as List).single,
        containsPair('due_at_local', '2026-11-17T00:00+08:00'),
      );
      final overview = TodoPanel.decode(
        run({'title': '工作概况'}, overview: true)['ui'],
        overview: true,
      )!;
      expect(overview.sections.map((s) => s.title), [
        '今日待办',
        '紧急待办',
        '逾期待办',
        '本周待办',
      ]);
      expect(overview.sections.map((s) => s.matchedCount), [2, 1, 2, 5]);
    },
  );

  test(
    'selected IDs preserve order and completed tasks; missing target fails',
    () {
      final result = run({
        'title': '先做这些',
        'scope': 'selected',
        'todo_ids': ['finished', 'later'],
      });
      expect(
        TodoPanel.decode(
          result['ui'],
          overview: false,
        )!.sections.single.todoIds,
        ['finished', 'later'],
      );
      expect(
        run({
          'title': '清单',
          'scope': 'selected',
          'todo_ids': ['removed'],
        }),
        containsPair('error', 'not_found'),
      );
      expect(
        run({
          'title': '清单',
          'scope': 'selected',
          'todo_ids': ['missing'],
        }),
        containsPair('error', 'not_found'),
      );
    },
  );

  test('empty scope produces an explicit empty panel', () {
    final result = run({
      'title': '不存在的内容',
      'scope': 'all',
      'query': 'nothing-matches',
    });
    final panel = TodoPanel.decode(result['ui'], overview: false)!;
    expect(panel.sections.single.todoIds, isEmpty);
    expect(panel.sections.single.matchedCount, 0);
  });

  test('category/query use shared AND filtering and include children', () {
    final scoped = AgentToolContext(
      now: now,
      localOffset: Duration.zero,
      snapshot: WorkspaceSnapshot([
        WorkspaceEntity(
          kind: WorkspaceEntityKind.category,
          id: 'parent',
          version: 1,
          createdAt: now,
          updatedAt: now,
          data: {'name': '工作'},
        ),
        WorkspaceEntity(
          kind: WorkspaceEntityKind.category,
          id: 'child',
          version: 1,
          createdAt: now,
          updatedAt: now,
          data: {'name': '项目', 'parent_id': 'parent'},
        ),
        todo('match-parent', category: 'parent'),
        todo('match-child', category: 'child'),
        todo('match-other'),
        todo('unrelated', category: 'child'),
      ]),
    );
    final result = const TodoPanelTool().call({
      'title': '项目',
      'scope': 'all',
      'category_id': 'parent',
      'query': 'match',
    }, scoped) as Map;
    expect(
      TodoPanel.decode(result['ui'], overview: false)!.sections.single.todoIds,
      ['match-child', 'match-parent'],
    );
    expect(
      run({'title': '项目', 'scope': 'all', 'category_id': 'missing'}),
      containsPair('error', 'category_not_found'),
    );
  });

  test('schemas are registered and malformed arguments are rejected', () {
    expect(AgentToolRegistry.read('show_todo_list'), isA<TodoPanelTool>());
    expect(AgentToolRegistry.read('show_todo_overview'), isA<TodoPanelTool>());
    final invalid = throwsA(
      anyOf(isA<AgentFailure>(), isA<WorkspaceFailure>()),
    );
    for (final args in <Map<String, Object?>>[
      {},
      {'title': '', 'scope': 'today'},
      {'title': 'a' * 61, 'scope': 'today'},
      {'title': 'a\nb', 'scope': 'today'},
      {'title': '清单', 'scope': 'unknown'},
      {'title': '清单', 'scope': 'today', 'limit': 201},
      {'title': '清单', 'scope': 'today', 'limit': 1.5},
      {'title': '清单', 'scope': 'today', 'extra': true},
      {
        'title': '清单',
        'scope': 'today',
        'todo_ids': ['later'],
      },
      {
        'title': '清单',
        'scope': 'selected',
        'todo_ids': ['later', 'later'],
      },
      {'title': '清单', 'scope': 'selected', 'todo_ids': []},
      {
        'title': '清单',
        'scope': 'selected',
        'todo_ids': [3],
      },
      {
        'title': '清单',
        'scope': 'selected',
        'todo_ids': ['later'],
        'query': 'x',
      },
    ]) {
      expect(() => run(args), invalid, reason: '$args');
    }
    for (final scopes in <Object>[
      <String>[],
      ['today', 'today'],
      ['selected'],
      ['nope'],
      'today',
    ]) {
      expect(
        () => run({'title': '总览', 'scopes': scopes}, overview: true),
        invalid,
      );
    }
  });

  test(
    'large displays collect existing query pages without losing records',
    () {
      final large = AgentToolContext(
        now: now,
        localOffset: const Duration(hours: 8),
        snapshot: WorkspaceSnapshot([
          for (var i = 0; i < 125; i++)
            todo('task-${i.toString().padLeft(3, '0')}'),
        ]),
      );
      final result = const TodoPanelTool().call({
        'title': '全部待办',
        'scope': 'all',
      }, large) as Map;
      final decoded = TodoPanel.decode(result['ui'], overview: false)!;
      expect(decoded.sections.single.todoIds, hasLength(120));
      expect(decoded.sections.single.todoIds.last, 'task-119');
      expect(decoded.sections.single.matchedCount, 125);
      final full = const TodoPanelTool().call({
        'title': '全部待办',
        'scope': 'all',
        'limit': 200,
      }, large) as Map;
      expect(
        TodoPanel.decode(full['ui'], overview: false)!.sections.single.todoIds,
        hasLength(125),
      );
    },
  );
}
