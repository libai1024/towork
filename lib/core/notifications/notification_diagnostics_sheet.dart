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
      title: '通知与提醒',
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
      if (mounted) error = '暂时无法访问系统通知设置，请重试。';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = ref.watch(notificationCoordinatorProvider);
    final maintenance = ref.watch(maintenanceRegistrationProvider);
    if (worker == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Text('本地工作区尚未就绪。'),
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
                      ? '正在检查系统权限…'
                      : !access.supported
                      ? '此平台暂不支持本地通知'
                      : access.enabled
                      ? '系统通知已开启'
                      : '系统通知未开启，提醒规则已保留。',
                ),
                const SizedBox(height: 4),
                Text(switch (maintenance) {
                  MaintenanceRegistration.scheduled => '后台维护已登记，执行时间由系统决定。',
                  MaintenanceRegistration.failed => '后台维护登记失败，前台仍可排期。',
                  MaintenanceRegistration.foregroundOnly => '仅前台维护，退出后暂停生成摘要。',
                }),
                if (maintenance == MaintenanceRegistration.failed)
                  AppButton(
                    label: '重试后台维护',
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
                Text('已排期 ${state.registered} 条，待排期 ${state.deferred} 条。'),
                if (access != null && access.supported && !access.exact)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('截止提醒可能延迟。需要准点提醒时请开启精确提醒。'),
                  ),
                if (state.failed > 0 || state.error || error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(error ?? '部分提醒未排期，请重试。'),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    AppButton(
                      label: '检查并重试',
                      onPressed: busy
                          ? null
                          : () =>
                                run(() => worker.refresh(retryFailures: true)),
                    ),
                    if (access?.supported == true && access?.enabled != true)
                      AppButton(
                        label: '开启系统通知',
                        onPressed: busy
                            ? null
                            : () => run(worker.requestPermission),
                      ),
                    if (access != null && access.supported && !access.exact)
                      AppButton(
                        label: '开启精确提醒',
                        onPressed: busy
                            ? null
                            : () => run(worker.requestExactPermission),
                      ),
                    AppButton(
                      label: '系统通知设置',
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
                          '排期详情',
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
                    '待办需设提醒规则。未来 30 天最多预排 60 条，每日摘要最多预排 7 天，使用排期时的本机数据。'
                    '后台或下次打开时补排。每日摘要按普通排期，省电、勿扰或强制停止可能影响送达。',
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
          child: const Text('开启系统通知'),
        );
      },
    );
  }
}
