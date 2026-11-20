part of 'chat_persistence.dart';

extension _ChatPromptContext on ChatPersistence {
  Future<AgentPromptContext> _promptContext(
    DateTime now, {
    required bool agentEnabled,
    required bool scoped,
    required bool voice,
  }) async {
    Future<T?> attempt<T>(Future<T> Function() read) async {
      try {
        return await read();
      } catch (_) {
        return null;
      }
    }

    final preferences = await attempt(
      () => SqliteAppPreferencesStore(db).loadOrCreate(),
    );
    final nickname = await attempt(() async {
      final row = await db
          .customSelect(
            'SELECT nickname FROM local_profiles WHERE singleton_id = 1',
            readsFrom: {db.localProfiles},
          )
          .getSingleOrNull();
      final name = row?.read<String>('nickname');
      // 默认占位名不是用户告诉我们的称呼。
      return name == '本地用户' ? null : name;
    });
    var categories = const <PromptCategory>[];
    var todos = const <PromptTodo>[];
    var openCount = -1;
    if (agentEnabled && !scoped) {
      categories =
          await attempt(() async {
            final rows = await db
                .customSelect(
                  'SELECT id, payload FROM work_categories '
                  'WHERE deleted_at IS NULL AND archived = 0 '
                  'ORDER BY sort_order ASC, id ASC LIMIT 200',
                  readsFrom: {db.workCategories},
                )
                .get();
            final data = {
              for (final row in rows)
                row.read<String>('id'): (jsonDecode(
                  row.read<String>('payload'),
                ) as Map).cast<String, Object?>(),
            };
            return [
              for (final entry in data.entries)
                PromptCategory(
                  id: entry.key,
                  path: [
                    if (data[entry.value['parent_id']]?['name']
                        case final String parent)
                      parent,
                    entry.value['name'] as String? ?? '',
                  ].join('/'),
                ),
            ]..sort((a, b) => a.path.compareTo(b.path));
          }) ??
          const [];
      const open = "deleted_at IS NULL AND status IN ('pending', 'inProgress')";
      openCount =
          await attempt(() async {
            final row = await db
                .customSelect(
                  'SELECT COUNT(*) AS total FROM work_todos WHERE $open',
                  readsFrom: {db.workTodos},
                )
                .getSingle();
            return row.read<int>('total');
          }) ??
          -1;
      todos =
          await attempt(() async {
            // 有截止的按时间先后（逾期在最前），没有截止的按最近改动。
            final rows = await db
                .customSelect(
                  'SELECT id, version, payload FROM work_todos WHERE $open '
                  'ORDER BY due_at IS NULL, due_at ASC, updated_at DESC, id ASC '
                  'LIMIT ${AgentPrompt.maxOpenTodos}',
                  readsFrom: {db.workTodos},
                )
                .get();
            return [
              for (final row in rows)
                () {
                  final data = (jsonDecode(row.read<String>('payload')) as Map)
                      .cast<String, Object?>();
                  final due = data['due_at'];
                  return PromptTodo(
                    id: row.read<String>('id'),
                    version: row.read<int>('version'),
                    title: data['title'] as String? ?? '',
                    dueAt: due is String ? DateTime.tryParse(due) : null,
                    priority: data['priority'] as String? ?? 'none',
                    repeating: data['series_id'] != null,
                  );
                }(),
            ];
          }) ??
          const [];
    }
    return AgentPromptContext(
      now: now,
      offset: now.timeZoneOffset,
      zoneName: now.timeZoneName,
      agentEnabled: agentEnabled,
      voice: voice,
      nickname: nickname,
      customInstructions: preferences?.customInstructions ?? '',
      vocabulary: preferences?.speechVocabulary ?? const [],
      permission: preferences?.permission,
      categories: categories,
      openTodos: todos,
      openTodoCount: openCount < 0 ? todos.length : openCount,
    );
  }
}
