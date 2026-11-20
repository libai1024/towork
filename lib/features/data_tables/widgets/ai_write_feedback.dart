import 'package:towork/l10n/repository_messages.dart';
import 'package:towork/l10n/strings.dart';
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
  final undoMessage = context.strings.undoneChangesReverted;
  final count = result.appliedChanges.length;
  AppToast.show(
    context,
    message: result.createsOnly
        ? context.strings.aiAddedRows(count)
        : context.strings.aiMadeChanges(count),
    duration: result.containsDeletion
        ? const Duration(seconds: 5)
        : const Duration(milliseconds: 2500),
    actionLabel: context.strings.undo,
    onAction: () {
      if (!store.mounted) return;
      try {
        store.undoLastApply();
        // The repository outlives its originating route. Only the optional
        // presentation callback belongs to that route's lifetime.
        if (context.mounted) onUndone?.call();
        showFeedback(undoMessage);
      } on RepositoryException catch (error) {
        showFeedback(repositoryErrorMessage(error));
      }
    },
  );
}
