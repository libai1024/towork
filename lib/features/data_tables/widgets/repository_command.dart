import 'package:towork/l10n/repository_messages.dart';
import 'package:towork/l10n/strings.dart';

import 'dart:async';

import '../../../core/workspace_actions.dart';
import '../../../domain/workspace/workspace_commands.dart';

import 'package:flutter/widgets.dart';

import '../../../core/widgets/app_toast.dart';
import '../../../domain/repositories/repository_error.dart';

/// Return false only for an expected, user-correctable repository failure.
/// Callers keep their editor open and publish success UI only on true.
/// Programming errors deliberately propagate instead of becoming a toast.
bool runRepositoryCommand(BuildContext context, VoidCallback command) {
  try {
    command();
    return true;
  } on RepositoryException catch (error) {
    if (context.mounted) {
      AppToast.show(context, message: repositoryErrorMessage(error));
    }
    return false;
  }
}

Future<bool> runDataCommand(
  BuildContext context,
  FutureOr<void> Function() command,
) async {
  try {
    await command();
    return true;
  } on RepositoryException catch (error) {
    if (context.mounted) {
      AppToast.show(context, message: repositoryErrorMessage(error));
    }
  } on WorkspaceFailure catch (error) {
    if (context.mounted) {
      AppToast.show(
        context,
        message: error.code == WorkspaceFailureCode.validation
            ? context.strings.invalidContentOrFieldFormatCheckAnd
            : workspaceErrorMessage(error),
      );
    }
  } on WorkspaceBusy {
    if (context.mounted) {
      AppToast.show(context, message: context.strings.savingPleaseWait);
    }
  }
  return false;
}
