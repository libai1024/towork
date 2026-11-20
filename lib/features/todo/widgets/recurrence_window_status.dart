import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/recurrence_window.dart';
import '../../../app/recurrence_window_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Honest range status: existing tasks remain usable while a local window is
/// incomplete. No spinner that implies foreground interaction must wait.
class RecurrenceWindowStatus extends ConsumerWidget {
  const RecurrenceWindowStatus({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(recurrenceWindowProvider);
    if (worker == null) return const SizedBox.shrink();
    return StreamBuilder<RecurrenceWindowState>(
      key: ObjectKey(worker),
      stream: worker.stream,
      initialData: worker.current,
      builder: (context, snapshot) {
        final state = snapshot.data ?? worker.current;
        if (state.seriesCount == 0 && state.problems.isEmpty) {
          return const SizedBox.shrink();
        }
        final date = state.through?.toLocal();
        final text = state.problems.isNotEmpty
            ? state.problems.values.contains(RecurrenceWindowProblem.calendar)
                  ? context.strings.someOccurrencesExceedAvailableTimeZoneData
                  : context.strings.someRecurringTasksAreStillPendingExisting
            : switch (state.phase) {
                RecurrenceWindowPhase.ready =>
                  context.strings.recurringTasksGeneratedThrough(
                    date!.year,
                    date.month,
                    date.day,
                    date.hour.toString().padLeft(2, '0'),
                    date.minute.toString().padLeft(2, '0'),
                  ),
                RecurrenceWindowPhase.waiting =>
                  context.strings.recurringTasksWillContinueAfterThisAction,
                RecurrenceWindowPhase.paused =>
                  context.strings.recurringTasksWillContinueWhenYouReopen,
                _ => context.strings.generatingRecurringTasksInBatches,
              };
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.of(context).labelSecondary,
                  ),
                ),
              ),
              if (state.problems.isNotEmpty) ...[
                const SizedBox(width: 8),
                AppButton(
                  key: const ValueKey('recurrence-window-retry'),
                  label: context.strings.retry,
                  type: AppButtonType.ghost,
                  onPressed: () => worker.refresh(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
