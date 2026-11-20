import 'package:towork/l10n/repository_messages.dart';
import 'package:towork/l10n/strings.dart';
import 'package:flutter/widgets.dart';

import '../app/workspace_ui_commands.dart';
import '../domain/repositories/repository_error.dart';
import '../domain/workspace/workspace_commands.dart';
import 'widgets/app_toast.dart';

export '../app/workspace_ui_commands.dart'
    show
        TodoFieldEdit,
        UiCategoryUndo,
        UiWorkspaceChange,
        WorkspaceBusy,
        WorkspaceUiCommands,
        workspaceUiCommandsProvider;

String workspaceErrorMessage(Object error) => switch (error) {
  WorkspaceBusy() => strings.savingTryAgainShortly,
  WorkspaceFailure(code: WorkspaceFailureCode.versionConflict) =>
    strings.recordChangedReopenAndTryAgain,
  WorkspaceFailure(code: WorkspaceFailureCode.idempotencyMismatch) =>
    strings.actionAlreadySubmittedCheckTheLatestRecord,
  WorkspaceFailure(code: WorkspaceFailureCode.validation) =>
    strings.invalidContentOrCategoryRelationshipCheckAnd,
  WorkspaceFailure(code: WorkspaceFailureCode.notFound) =>
    strings.recordNoLongerExistsRefreshAndTry,
  RepositoryException() => repositoryErrorMessage(error),
  _ => strings.couldntSaveYourDataIsSafeTry,
};

Future<T?> workspaceUi<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  try {
    return await action();
  } catch (error) {
    if (context.mounted) {
      AppToast.show(context, message: workspaceErrorMessage(error));
    }
    return null;
  }
}
