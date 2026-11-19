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
    if (context.mounted) AppToast.show(context, message: error.message);
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
    if (context.mounted) AppToast.show(context, message: error.message);
  } on WorkspaceFailure catch (error) {
    if (context.mounted) {
      AppToast.show(
        context,
        message: error.code == WorkspaceFailureCode.validation
            ? '内容或字段格式无效，请检查后重试'
            : workspaceErrorMessage(error),
      );
    }
  } on WorkspaceBusy {
    if (context.mounted) AppToast.show(context, message: '正在保存，请稍候');
  }
  return false;
}
