import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/notification_provider.dart';
import '../../app/notification_coordinator.dart';
import '../../app/maintenance_registration_provider.dart';
import '../../app/background_maintenance.dart';
import '../widgets/app_button.dart';
import '../widgets/app_pressable.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../widgets/app_sheet.dart';
import '../../theme/app_text_styles.dart';

Future<void> showNotificationDiagnostics(BuildContext context) =>
    AppSheet.show<void>(
      context,
      title: context.strings.notificationsAndReminders,
      child: const NotificationDiagnosticsSheet(),
    );

class NotificationDiagnosticsSheet extends ConsumerStatefulWidget {
  const NotificationDiagnosticsSheet({super.key});
  @override
  ConsumerState<NotificationDiagnosticsSheet> createState() =>
      _NotificationDiagnosticsSheetState();
}

class _NotificationDiagnosticsSheetState
    extends ConsumerState<NotificationDiagnosticsSheet> {
  bool busy = false;
  String? error;
  bool _showDetails = false;
  Future<void> run(Future<void> Function() work) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await work();
    } catch (_) {
      if (mounted) {
        error = context.strings.couldntOpenNotificationSettingsTryAgain;
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = ref.watch(notificationCoordinatorProvider);
    final maintenance = ref.watch(maintenanceRegistrationProvider);
    if (worker == null) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Text(context.strings.localWorkspaceIsntReady),
      );
    }
    return StreamBuilder<NotificationState>(
      stream: worker.stream,
      initialData: worker.current,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        final access = state.access;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  access == null
                      ? context.strings.checkingPermissions
                      : !access.supported
                      ? context
                            .strings
                            .localNotificationsAreUnavailableOnThisPlatform
                      : access.enabled
                      ? context.strings.systemNotificationsEnabled
                      : context.strings.notificationsAreOffYourReminderRulesAre,
                ),
                const SizedBox(height: 4),
                Text(switch (maintenance) {
                  MaintenanceRegistration.scheduled =>
                    context
                        .strings
                        .backgroundMaintenanceRegisteredTheSystemControlsTiming,
                  MaintenanceRegistration.failed =>
                    context
                        .strings
                        .backgroundRegistrationFailedRemindersCanStillBe,
                  MaintenanceRegistration.foregroundOnly =>
                    context
                        .strings
                        .foregroundMaintenanceOnlyDigestGenerationPausesWhen,
                }),
                if (maintenance == MaintenanceRegistration.failed)
                  AppButton(
                    label: context.strings.retryBackgroundMaintenance,
                    type: AppButtonType.ghost,
                    onPressed: busy
                        ? null
                        : () => run(() async {
                            final result =
                                await registerBackgroundMaintenance();
                            if (mounted) {
                              ref
                                      .read(
                                        maintenanceRegistrationProvider
                                            .notifier,
                                      )
                                      .state =
                                  result;
                            }
                          }),
                  ),
                const SizedBox(height: 4),
                Text(
                  context.strings.scheduledPending(
                    state.registered,
                    state.deferred,
                  ),
                ),
                if (access != null && access.supported && !access.exact)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      context.strings.dueRemindersMayArriveLateEnableExact,
                    ),
                  ),
                if (state.failed > 0 || state.error || error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      error ??
                          context.strings.someRemindersWerentScheduledTryAgain,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    AppButton(
                      label: context.strings.checkAndRetry,
                      onPressed: busy
                          ? null
                          : () =>
                                run(() => worker.refresh(retryFailures: true)),
                    ),
                    if (access?.supported == true && access?.enabled != true)
                      AppButton(
                        label: context.strings.enableNotifications,
                        onPressed: busy
                            ? null
                            : () => run(worker.requestPermission),
                      ),
                    if (access != null && access.supported && !access.exact)
                      AppButton(
                        label: context.strings.enableExactAlarms,
                        onPressed: busy
                            ? null
                            : () => run(worker.requestExactPermission),
                      ),
                    AppButton(
                      label: context.strings.systemNotificationSettings,
                      type: AppButtonType.ghost,
                      onPressed: busy
                          ? null
                          : () => run(worker.service.openSettings),
                    ),
                  ],
                ),
                Semantics(
                  expanded: _showDetails,
                  child: AppPressable(
                    onTap: () => setState(() => _showDetails = !_showDetails),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.strings.scheduleDetails,
                          style: AppTextStyles.footnote.copyWith(
                            color: AppColors.of(context).labelSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showDetails
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showDetails)
                  Text(
                    '${context.strings.setAReminderOnTheTaskUp}'
                    '${context.strings.schedulingResumesInTheBackgroundOrWhen}',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.of(context).labelSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shown beside actual reminder editing; saving remains available when the OS
/// permission is off. Isolated UI fixtures without a runtime show no fake state.
class NotificationPermissionHint extends ConsumerWidget {
  const NotificationPermissionHint({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(notificationCoordinatorProvider);
    if (worker == null) return const SizedBox.shrink();
    return StreamBuilder<NotificationState>(
      stream: worker.stream,
      initialData: worker.current,
      builder: (context, snapshot) {
        if (snapshot.data?.access?.enabled != false) {
          return const SizedBox.shrink();
        }
        return TextButton(
          onPressed: () => showNotificationDiagnostics(context),
          child: Text(context.strings.enableNotifications),
        );
      },
    );
  }
}
