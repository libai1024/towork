import 'package:flutter/widgets.dart';

import '../app/workspace_ui_commands.dart';
import '../domain/repositories/repository_error.dart';
import '../domain/workspace/workspace_commands.dart';
import 'widgets/app_toast.dart';

export '../app/workspace_ui_commands.dart'
    show
        UiCategoryUndo,
        UiWorkspaceChange,
        WorkspaceBusy,
        WorkspaceUiCommands,
        workspaceUiCommandsProvider;

String workspaceErrorMessage(Object error) => switch (error) {
  WorkspaceBusy() => '正在保存，请稍后再试',
  WorkspaceFailure(code: WorkspaceFailureCode.versionConflict) =>
    '记录已变化，请重新打开后再操作',
  WorkspaceFailure(code: WorkspaceFailureCode.idempotencyMismatch) =>
    '该操作已提交，请检查最新记录',
  WorkspaceFailure(code: WorkspaceFailureCode.validation) => '内容或分类关系无效，请检查后重试',
  WorkspaceFailure(code: WorkspaceFailureCode.notFound) => '记录已不存在，请刷新后重试',
  RepositoryException() => error.message,
  _ => '保存失败，原数据已保留，请重试',
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
