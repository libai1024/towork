import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/workspace_model_codec.dart';
import '../domain/models/todo.dart';
import '../domain/recurrence/recurrence_plans.dart';
import '../domain/workspace/workspace_commands.dart';
import 'local_workspace_session.dart';
import 'workspace_clock.dart';
import 'workspace_ui_commands.dart';

final recurrenceCommandsProvider = Provider<RecurrenceCommands?>((ref) {
  final session = ref.watch(localWorkspaceSessionProvider);
  return session == null
      ? null
      : RecurrenceCommands(session, clock: ref.watch(workspaceNowProvider));
});

/// App-owned bridge for prepared recurrence commands. It publishes only durable
/// receipts and shares the exact same workspace and undo path as ordinary Todo.
/// The UI retains a prepared command while awaiting scope confirmation/retry.
class RecurrenceCommands {
  RecurrenceCommands(this.session, {required this.clock});
  final LocalWorkspaceSession session;
  final DateTime Function() clock;
  RecurrencePlans get plans => RecurrencePlans(session.snapshot, now: clock());

  bool hasChanges(Todo before, Todo after) =>
      canonicalWorkspaceJson(todoWorkspaceData(before)) !=
      canonicalWorkspaceJson(todoWorkspaceData(after));

  void _checkDisplayed(Todo todo) {
    final current = session.snapshot.find(WorkspaceEntityKind.todo, todo.id);
    if (current == null ||
        current.isDeleted ||
        current.version != todo.version) {
      throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
    }
  }

  DateTime _through(Todo todo) {
    final now = clock().toUtc();
    var anchor = (todo.occurrenceAt ?? todo.dueAt ?? now).toUtc();
    if (todo.dueAt != null && todo.dueAt!.isAfter(anchor)) {
      anchor = todo.dueAt!.toUtc();
    }
    return (anchor.isAfter(now) ? anchor : now).add(const Duration(days: 90));
  }

  RecurrenceProposal startProposal(Todo todo, String rule, String zone) {
    _checkDisplayed(todo);
    final command = plans.start(
      todo.id,
      rule: rule,
      timezone: zone,
      operationId: newWorkspaceId('repeat'),
      through: _through(todo),
    );
    return RecurrenceProposal(
      title: '开启重复待办',
      choices: [_choice('从本次开始', command, future: true)],
    );
  }

  RecurrenceProposal editProposal(Todo before, Todo after) {
    _checkDisplayed(before);
    if (before.id != after.id || before.version != after.version) {
      throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
    }
    final original = todoWorkspaceData(before),
        updated = todoWorkspaceData(after);
    final patch = <String, Object?>{
      for (final key in updated.keys)
        if (canonicalWorkspaceJson(original[key]) !=
            canonicalWorkspaceJson(updated[key]))
          key: updated[key],
    };
    return _scopes(
      '修改重复待办',
      (scope) => plans.edit(
        before.id,
        patch,
        scope: scope,
        operationId: newWorkspaceId('repeat'),
        through: _through(after),
      ),
    );
  }

  RecurrenceProposal deleteProposal(Todo todo) {
    _checkDisplayed(todo);
    return _scopes(
      '删除重复待办',
      (scope) => plans.delete(
        todo.id,
        scope: scope,
        operationId: newWorkspaceId('repeat'),
      ),
      deleting: true,
    );
  }

  RecurrenceProposal _scopes(
    String title,
    WorkspaceCommand Function(RecurrenceScope) prepare, {
    bool deleting = false,
  }) {
    final choices = <RecurrenceChoice>[];
    final notes = <String>[];
    for (final scope in RecurrenceScope.values) {
      try {
        choices.add(
          _choice(
            scope == RecurrenceScope.current ? '仅本次' : '本次及以后',
            prepare(scope),
            future: scope == RecurrenceScope.currentAndFuture,
          ),
        );
      } on WorkspaceFailure catch (error) {
        // Some operations are intrinsically one-scope: changing the calendar
        // cannot edit one slot; a superseded historical slot cannot fork again.
        if (error.code != WorkspaceFailureCode.validation) rethrow;
        notes.add(
          scope == RecurrenceScope.current
              ? '重复规则或时区的修改需要应用于本次及以后。'
              : '本次及以后暂不可用，请检查截止日期和系列状态；记录较多时也可能超过单次处理上限。',
        );
      }
    }
    if (choices.isEmpty) {
      throw const WorkspaceFailure(WorkspaceFailureCode.validation);
    }
    return RecurrenceProposal(
      title: title,
      choices: choices,
      deleting: deleting,
      notes: notes,
    );
  }

  RecurrenceChoice _choice(
    String label,
    WorkspaceCommand command, {
    required bool future,
  }) {
    final changes = <RecurrenceChange>[];
    for (final action in command.actions.where(
      (a) => a.kind == WorkspaceEntityKind.todo,
    )) {
      final before = session.snapshot
          .find(WorkspaceEntityKind.todo, action.entityId)
          ?.data;
      changes.add(
        RecurrenceChange(
          action.mutation,
          before,
          action.mutation == WorkspaceMutationKind.delete ? null : action.patch,
          beforeCategory: session.categories
              .byId(before?['category_id'] as String?)
              ?.name,
          afterCategory: session.categories
              .byId(action.patch['category_id'] as String?)
              ?.name,
        ),
      );
    }
    return RecurrenceChoice(
      label,
      command,
      List.unmodifiable(changes),
      future: future,
    );
  }

  Future<UiWorkspaceChange<WorkspaceReceipt>> execute(
    WorkspaceCommand command,
  ) async {
    final receipt = await session.execute(command);
    final undoId = newWorkspaceId('undo');
    return UiWorkspaceChange(
      receipt,
      () => session.undo(receipt.changesetId, undoId),
    );
  }
}

class RecurrenceProposal {
  RecurrenceProposal({
    required this.title,
    required List<RecurrenceChoice> choices,
    this.deleting = false,
    List<String> notes = const [],
  }) : choices = List.unmodifiable(choices),
       notes = List.unmodifiable(notes);
  final String title;
  final List<RecurrenceChoice> choices;
  final bool deleting;
  final List<String> notes;
}

class RecurrenceChoice {
  const RecurrenceChoice(
    this.label,
    this.command,
    this.changes, {
    required this.future,
  });
  final String label;
  final WorkspaceCommand command;
  final List<RecurrenceChange> changes;
  final bool future;
  int count(WorkspaceMutationKind kind) =>
      changes.where((c) => c.kind == kind).length;
}

class RecurrenceChange {
  const RecurrenceChange(
    this.kind,
    this.before,
    this.after, {
    this.beforeCategory,
    this.afterCategory,
  });
  final WorkspaceMutationKind kind;
  final Map<String, Object?>? before;
  final Map<String, Object?>? after;
  final String? beforeCategory;
  final String? afterCategory;
}
