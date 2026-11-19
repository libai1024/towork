import '../../domain/ai/agent_run.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/chat/todo_panel.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../domain/workspace/workspace_queries.dart';
import '../../domain/workspace/workspace_validation.dart';
import '../agent_time.dart';
import '../agent_tool_registry.dart';

const _scopes = {
  'today': '今日待办',
  'urgent': '紧急待办',
  'overdue': '逾期待办',
  'week': '本周待办',
  'in_progress': '进行中',
  'undated': '未定期待办',
  'all': '全部待办',
};

/// Read-only display tools use the existing query contract and committed
/// snapshot. The user can subsequently complete/edit tasks through normal UI.
class TodoPanelTool implements AgentReadTool {
  const TodoPanelTool({this.overview = false});
  final bool overview;

  @override
  String get name => overview ? 'show_todo_overview' : 'show_todo_list';

  @override
  JsonObject get schema => agentToolSchema(
    name,
    overview
        ? 'Display a compact interactive todo overview in the conversation. '
              'Users switch between named sections and complete or edit real '
              'tasks. Counts and membership use the committed snapshot. '
              'Use for a daily briefing or multiple task groups; do not repeat '
              'the full lists in prose. No tasks or saved lists are created.'
        : 'Display a titled interactive list of existing todos in the '
              'conversation. Use for today, urgent, overdue, this week, '
              'in-progress, undated or a curated selection. Users can complete '
              'or edit the actual tasks. Urgent means priority urgent; today '
              'includes all active tasks due on the local day, including those '
              'already overdue today; week is the current Monday-Sunday. '
              'All scopes exclude completed/cancelled tasks, except selected '
              'IDs which preserve the given order and status. category_id and '
              'query narrow the scope with AND. Call after writes in a separate '
              'batch to display their committed result. No tasks or saved lists '
              'are created. Do not duplicate the list in prose.',
    {
      'title': {'type': 'string', 'minLength': 1, 'maxLength': 60},
      if (overview)
        'scopes': {
          'type': 'array',
          'items': {'type': 'string', 'enum': _scopes.keys.toList()},
          'minItems': 1,
          'maxItems': 5,
          'uniqueItems': true,
          'description': 'Default today, urgent, overdue, week.',
        }
      else ...{
        'scope': {
          'type': 'string',
          'enum': [..._scopes.keys, 'selected'],
        },
        'todo_ids': {
          'type': 'array',
          'items': {'type': 'string'},
          'minItems': 1,
          'maxItems': TodoPanelSection.maxItems,
          'uniqueItems': true,
          'description': 'Required only for selected; IDs from a prior query.',
        },
      },
      'category_id': {
        'type': ['string', 'null'],
        'description':
            'Omit for all, null for uncategorized; includes children.',
      },
      'query': {'type': 'string', 'maxLength': 200},
      'limit': {
        'type': 'integer',
        'minimum': 1,
        'maximum': TodoPanelSection.maxItems,
        'description': 'Maximum tasks per section, default 120. The UI shows five tasks per page.',
      },
    },
    required: overview ? const ['title'] : const ['title', 'scope'],
  );

  @override
  Object? call(JsonObject args, AgentToolContext context) {
    requireToolKeys(
      args,
      {
        'title',
        'category_id',
        'query',
        'limit',
        if (overview) 'scopes' else ...['scope', 'todo_ids'],
      },
      required: {'title', if (!overview) 'scope'},
    );
    final title = args['title'];
    final limit = args['limit'] ?? 120;
    if (title is! String ||
        title.trim().isEmpty ||
        title.runes.length > 60 ||
        title.contains(RegExp(r'[\x00-\x1f]')) ||
        limit is! int ||
        limit < 1 ||
        limit > TodoPanelSection.maxItems) {
      _invalid();
    }
    final scopes = overview
        ? args['scopes'] ?? ['today', 'urgent', 'overdue', 'week']
        : [args['scope']];
    if (scopes is! List ||
        scopes.isEmpty ||
        scopes.length > 5 ||
        scopes.toSet().length != scopes.length ||
        scopes.any(
          (s) => !_scopes.containsKey(s) && !(s == 'selected' && !overview),
        )) {
      _invalid();
    }
    if (scopes.singleOrNull != 'selected' && args.containsKey('todo_ids')) {
      _invalid();
    }
    final sections = <TodoPanelSection>[];
    final details = <JsonObject>[];
    for (final scope in scopes.cast<String>()) {
      final result = scope == 'selected'
          ? _selected(args, context.snapshot)
          : _queryPages(context.snapshot, {
              ..._filters(scope, context),
              if (args.containsKey('category_id')) ...{
                'category_id': args['category_id'],
                'include_descendants': args['category_id'] != null,
              },
              if (args.containsKey('query')) 'query': args['query'],
            }, limit);
      if (result.containsKey('error')) return result;
      final items = (result['items']! as List).cast<JsonObject>();
      sections.add(
        TodoPanelSection(
          title: overview ? _scopes[scope]! : title.trim(),
          todoIds: items.map((item) => item['id']! as String),
          matchedCount: result['matched_count']! as int,
        ),
      );
      details.add({
        'scope': scope,
        'matched_count': result['matched_count'],
        'items': [
          for (final item in items)
            {
              for (final key in ['id', 'version', 'title', 'status', 'due_at'])
                if (item.containsKey(key)) key: item[key],
            },
        ],
      });
    }
    return {
      'ui': TodoPanel(
        title: title.trim(),
        asOfLocal: AgentTime.local(context.now, context.localOffset),
        overview: overview,
        sections: sections,
      ).toJson(),
      'sections': AgentTime.localize(details, context.localOffset),
      'scope': 'materialized_records_only',
    };
  }

  JsonObject _selected(JsonObject args, WorkspaceSnapshot snapshot) {
    if (args.containsKey('category_id') ||
        args.containsKey('query') ||
        args.containsKey('limit')) {
      _invalid();
    }
    final ids = args['todo_ids'];
    if (ids is! List ||
        ids.isEmpty ||
        ids.length > TodoPanelSection.maxItems ||
        ids.toSet().length != ids.length) {
      _invalid();
    }
    final items = <JsonObject>[];
    for (final id in ids) {
      if (id is! String) _invalid();
      validateWorkspaceId(id);
      final todo = snapshot.find(WorkspaceEntityKind.todo, id);
      if (todo == null || todo.isDeleted) {
        return {'error': 'not_found', 'id': id};
      }
      items.add({'id': todo.id, 'version': todo.version, ...todo.data});
    }
    return {'items': items, 'matched_count': items.length};
  }

  JsonObject _filters(String scope, AgentToolContext context) {
    final local = context.now.toUtc().add(context.localOffset);
    final start = DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).subtract(context.localOffset);
    final monday = start.subtract(Duration(days: local.weekday - 1));
    return {
      'status': scope == 'in_progress' ? 'inProgress' : 'active',
      'order_by': 'due_at',
      ...switch (scope) {
        'today' => {
          'due_from': start.toIso8601String(),
          'due_before': start.add(const Duration(days: 1)).toIso8601String(),
        },
        'week' => {
          'due_from': monday.toIso8601String(),
          'due_before': monday.add(const Duration(days: 7)).toIso8601String(),
        },
        'urgent' => {'priority': 'urgent'},
        'overdue' => {'due_before': context.now.toUtc().toIso8601String()},
        'undated' => {'no_due': true},
        _ => <String, Object?>{},
      },
    };
  }

  JsonObject _queryPages(
    WorkspaceSnapshot snapshot,
    JsonObject filters,
    int limit,
  ) {
    final items = <JsonObject>[];
    String? token;
    var matched = 0;
    do {
      final result = WorkspaceQueries.todos(snapshot, {
        ...filters,
        'limit': (limit - items.length).clamp(1, 50),
        'page_token': ?token,
      });
      if (result.containsKey('error')) return result;
      items.addAll((result['items']! as List).cast<JsonObject>());
      matched = result['matched_count']! as int;
      token = result['next_page_token'] as String?;
    } while (token != null && items.length < limit);
    return {'items': items, 'matched_count': matched};
  }

  Never _invalid() => throw const AgentFailure(AgentFailureCode.invalid);
}
