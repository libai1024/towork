import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/app_toast.dart';
import '../application/ai_write_policy.dart';

final dataTableAiPolicyProvider = Provider<AiWritePolicy>(
  (ref) => AiWritePolicy(ref.watch(dataTableProvider.notifier)),
);

void showAiWriteFeedback(
  BuildContext context,
  DataTableStore store,
  AiWriteResult result, {
  VoidCallback? onUndone,
}) {
  if (!result.hasWrites) return;
  final showFeedback = AppToast.presenter(context);
  final count = result.appliedChanges.length;
  AppToast.show(
    context,
    message: result.createsOnly ? 'AI 新增了 $count 行' : 'AI 更新了 $count 处',
    duration: result.containsDeletion
        ? const Duration(seconds: 5)
        : const Duration(milliseconds: 2500),
    actionLabel: '撤销',
    onAction: () {
      if (!store.mounted) return;
      try {
        store.undoLastApply();
        // The repository outlives its originating route. Only the optional
        // presentation callback belongs to that route's lifetime.
        if (context.mounted) onUndone?.call();
        showFeedback('已撤销，改动已还原');
      } on RepositoryException catch (error) {
        showFeedback(error.message);
      }
    },
  );
}
