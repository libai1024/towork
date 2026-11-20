import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/todo.dart';
import '../../domain/workspace/todo_step_edit.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_button.dart';
import '../workspace_actions.dart';
import 'recurrence_action_sheet.dart';

Future<bool> confirmRemainingSteps(
  BuildContext context,
  Iterable<Todo> todos,
) async {
  final remaining = todos
      .where((t) => t.isActive)
      .fold(0, (n, t) => n + t.steps.length - t.completedSteps);
  if (remaining == 0) return true;
  return await AppSheet.show<bool>(
        context,
        title: context.strings.unfinishedSteps(remaining),
        child: Builder(
          builder: (sheet) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: context.strings.back,
                    type: AppButtonType.ghost,
                    onPressed: () => Navigator.of(sheet).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: context.strings.completeTaskConfirmremainingsteps,
                    onPressed: () => Navigator.of(sheet).pop(true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}

Future<bool> commitTodoStep(
  BuildContext context,
  WidgetRef ref,
  Todo todo,
  TodoStepEdit edit,
) async {
  final result = await workspaceUi(context, () async {
    final patch = edit.patch(todo.steps, todo.status);
    final status = patch['status'] == null
        ? todo.status
        : TodoStatus.values.byName(patch['status']! as String);
    final after = todo.copyWith(
      steps: TodoStep.decode(patch['steps']),
      status: status,
      completedAt: status == TodoStatus.done
          ? todo.completedAt ?? DateTime.now()
          : null,
    );
    if (todo.seriesId != null && edit.action != StepAction.check) {
      return saveTodoEdit(context, ref, todo, after);
    }
    final receipt = await ref.read(workspaceUiCommandsProvider).run((draft, _) {
      final current = draft.byId(todo.id);
      if (current == null || current.version != todo.version) {
        throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
      }
      draft.updateTodo(after);
    });
    if (context.mounted &&
        (edit.action == StepAction.check || edit.action == StepAction.remove)) {
      final report = AppToast.presenter(context);
      AppToast.show(
        context,
        message: status != todo.status
            ? (status == TodoStatus.done
                  ? context.strings.taskCompleted
                  : context.strings.taskReopened)
            : edit.action == StepAction.remove
            ? context.strings.stepDeleted
            : context.strings.progressUpdated,
        actionLabel: context.strings.undo,
        onAction: () async {
          try {
            await receipt.undo();
            report(strings.undone);
          } catch (error) {
            report(workspaceErrorMessage(error));
          }
        },
      );
    }
    return true;
  });
  return result == true;
}
