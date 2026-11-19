import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_preferences_provider.dart';
import '../../app/model_settings_provider.dart';
import '../../app/routes.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/settings/model_account_service.dart';
import '../../domain/settings/model_accounts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../core/ai/model_failure_text.dart';
import '../../core/ai/model_identity.dart';
import '../../core/ai/quota_widgets.dart';
import 'widgets/settings_shared.dart';
import 'widgets/billing_mark.dart';

class ModelAccountsPage extends ConsumerStatefulWidget {
  const ModelAccountsPage({super.key});

  @override
  ConsumerState<ModelAccountsPage> createState() => _ModelAccountsPageState();
}

class _ModelAccountsPageState extends ConsumerState<ModelAccountsPage> {
  final _refreshing = <String>{};
  bool _busy = false;
  bool _autoRefreshed = false;

  Future<ModelAccountService?> _service() async {
    try {
      return await ref.read(modelAccountServiceProvider.future);
    } catch (_) {
      if (mounted) AppToast.show(context, message: '本地配置暂时无法读取，请重试');
      return null;
    }
  }

  /// 进入页面时静默刷新一次；失败不打扰，卡片保留上次结果。
  void _refreshOnce(ModelAccountsSnapshot snapshot) {
    if (_autoRefreshed) return;
    _autoRefreshed = true;
    for (final account in snapshot.accounts) {
      if (account.hasCredential &&
          account.descriptor.quota != QuotaSource.none) {
        unawaited(_refresh(account, silent: true));
      }
    }
  }

  Future<void> _refresh(ModelAccount account, {bool silent = false}) async {
    if (_refreshing.contains(account.id)) return;
    final service = await _service();
    if (service == null || !mounted) return;
    setState(() => _refreshing.add(account.id));
    try {
      await service.refreshQuota(account.id);
      if (mounted && !silent) AppToast.show(context, message: '额度已更新');
    } catch (error) {
      if (mounted && !silent) {
        AppToast.show(
          context,
          message:
              error is ModelFailure &&
                  error.code == ModelFailureCode.configuration
              ? '这个服务商没有额度查询接口'
              : '额度查询失败：${describeModelSettingsError(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing.remove(account.id));
    }
  }

  Future<void> _run(
    Future<void> Function(ModelAccountService service) work, {
    String? done,
  }) async {
    if (_busy) return;
    final service = await _service();
    if (service == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await work(service);
      if (mounted && done != null) AppToast.show(context, message: done);
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: describeModelSettingsError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(ModelAccountsSnapshot snapshot, int index, int delta) {
    final ids = [for (final account in snapshot.accounts) account.id];
    final target = index + delta;
    if (target < 0 || target >= ids.length) return Future.value();
    final id = ids.removeAt(index);
    ids.insert(target, id);
    return _run((service) => service.reorder(ids));
  }

  Future<void> _confirmRemove(ModelAccount account) async {
    final c = AppColors.of(context);
    final confirmed = await AppSheet.show<bool>(
      context,
      title: '删除这个账户？',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${account.descriptor.shortLabel} 的配置和保存在这台设备上的 Key 会一并删除，'
              '无法恢复。历史对话不受影响。',
              style: AppTextStyles.body.copyWith(color: c.labelSecondary),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (sheet) => AppButton(
                key: const ValueKey('account-remove-confirm'),
                label: '删除账户',
                type: AppButtonType.destructive,
                expand: true,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run((service) => service.remove(account.id), done: '账户已删除');
  }

  void _openMenu(ModelAccountsSnapshot snapshot, int index) {
    final account = snapshot.accounts[index];
    final active = snapshot.activeId == account.id;
    AppSheet.show<void>(
      context,
      titleLeading: ProviderLogo(account.profile.product),
      title:
          '${account.descriptor.shortLabel} ${shortModelLabel(account.profile.model)}',
      child: Builder(
        builder: (sheet) {
          void close() => Navigator.of(sheet).pop();
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '优先级 ${index + 1}${account.autoRoute ? '' : '  仅手动'}',
                        style: AppTextStyles.caption,
                      ),
                      if (account.hasCredential && account.quota != null)
                        AccountQuotaBlock(
                          account: account,
                          now: DateTime.now().toUtc(),
                        ),
                    ],
                  ),
                ),
                if (!active && account.hasCredential)
                  SheetOptionRow(
                    icon: LucideIcons.circleCheck,
                    title: '设为当前使用',
                    onTap: () {
                      close();
                      _run(
                        (service) => service.activate(account.id),
                        done: '已切换为 ${account.descriptor.shortLabel}',
                      );
                    },
                  ),
                SheetOptionRow(
                  icon: LucideIcons.pencilLine,
                  title: '编辑模型与 Key',
                  onTap: () {
                    close();
                    context.push(AppRoutes.modelAccount(account.id));
                  },
                ),
                if (account.descriptor.quota != QuotaSource.none &&
                    account.hasCredential)
                  SheetOptionRow(
                    icon: LucideIcons.refreshCw,
                    title: '刷新额度',
                    onTap: () {
                      close();
                      _refresh(account);
                    },
                  ),
                if (account.coolingAt(DateTime.now().toUtc()))
                  SheetOptionRow(
                    icon: LucideIcons.timerReset,
                    title: '解除暂停',
                    subtitle: '恢复参与自动换用',
                    onTap: () {
                      close();
                      _run(
                        (service) => service.clearCooldown(account.id),
                        done: '已解除暂停',
                      );
                    },
                  ),
                SheetOptionRow(
                  icon: account.autoRoute
                      ? LucideIcons.routeOff
                      : LucideIcons.route,
                  title: account.autoRoute ? '不参与自动换用' : '参与自动换用',
                  onTap: () {
                    close();
                    _run(
                      (service) =>
                          service.setAutoRoute(account.id, !account.autoRoute),
                    );
                  },
                ),
                if (index > 0)
                  SheetOptionRow(
                    icon: LucideIcons.arrowUp,
                    title: '提高优先级',
                    onTap: () {
                      close();
                      _move(snapshot, index, -1);
                    },
                  ),
                if (index < snapshot.accounts.length - 1)
                  SheetOptionRow(
                    icon: LucideIcons.arrowDown,
                    title: '降低优先级',
                    onTap: () {
                      close();
                      _move(snapshot, index, 1);
                    },
                  ),
                SheetOptionRow(
                  icon: LucideIcons.trash2,
                  title: '删除账户',
                  onTap: () {
                    close();
                    _confirmRemove(account);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleAutoRoute(bool value) async {
    final saved = await savePreferences(context, ref, {'auto_route': value});
    if (!mounted || !saved) return;
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final accounts = ref.watch(modelAccountsProvider);
    final autoRoute = ref.watch(
      appPreferencesSnapshotProvider.select((p) => p.autoRoute),
    );
    final now = DateTime.now().toUtc();
    final snapshot = accounts.valueOrNull;
    if (snapshot != null) _refreshOnce(snapshot);

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            SettingsNavBar(
              title: '模型与额度',
              actions: [
                if (snapshot != null)
                  WorkspaceToolbarGroup(
                    children: [
                      WorkspaceToolbarAction(
                        key: const ValueKey('account-add'),
                        label: '添加模型账户',
                        text: snapshot.accounts.isEmpty ? '添加' : null,
                        icon: LucideIcons.plus,
                        onTap: () => context.push(AppRoutes.modelAccountNew),
                      ),
                    ],
                  ),
              ],
              onBack: () => context.popOrGo(AppRoutes.settings),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: switch (accounts) {
                    AsyncData(:final value) => ListView(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        8,
                        0,
                        AppSpacing.xxl,
                      ),
                      children: [
                        if (value.accounts.isEmpty)
                          const _EmptyAccounts()
                        else ...[
                          for (var i = 0; i < value.accounts.length; i++)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                              child: _AccountCard(
                                key: ValueKey(
                                  'account-${value.accounts[i].id}',
                                ),
                                account: value.accounts[i],
                                active: value.activeId == value.accounts[i].id,
                                priority: i + 1,
                                now: now,
                                refreshing: _refreshing.contains(
                                  value.accounts[i].id,
                                ),
                                onTap: () => context.push(
                                  AppRoutes.modelAccount(value.accounts[i].id),
                                ),
                                onMenu: () => _openMenu(value, i),
                                onRefresh: () => _refresh(value.accounts[i]),
                              ),
                            ),
                        ],
                        const SizedBox(height: 8),
                        SettingsGroupCard(
                          dividerIndent: 16,
                          footer: Text(
                            '额度用尽、限流或 Key 失效时，按优先级切换账户。',
                            style: AppTextStyles.caption.copyWith(
                              color: c.labelSecondary,
                            ),
                          ),
                          children: [
                            SettingsSwitchRow(
                              key: const ValueKey('auto-route-switch'),
                              title: '额度用尽时自动换用',
                              value: autoRoute,
                              onChanged: _toggleAutoRoute,
                            ),
                          ],
                        ),
                      ],
                    ),
                    AsyncError() => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '本地配置暂时无法读取',
                            style: AppTextStyles.body.copyWith(
                              color: c.labelSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.invalidate(modelAccountServiceProvider);
                              ref.invalidate(modelAccountsProvider);
                            },
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                    _ => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        '还没有模型账户',
        style: AppTextStyles.body.copyWith(color: c.labelSecondary),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    super.key,
    required this.account,
    required this.active,
    required this.priority,
    required this.now,
    required this.refreshing,
    required this.onTap,
    required this.onMenu,
    required this.onRefresh,
  });

  final ModelAccount account;
  final bool active;
  final int priority;
  final DateTime now;
  final bool refreshing;
  final VoidCallback onTap;
  final VoidCallback onMenu;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final cooling = account.coolingAt(now);
    final hasQuotaApi = account.descriptor.quota != QuotaSource.none;
    final windows = account.quota?.windows ?? const [];
    final unavailable = !account.hasCredential || cooling;
    final quota = account.quota;
    final text = unavailable
        ? accountStatusLabel(account, now)
        : quota?.balance != null
        ? '余额 ${balanceLabel(quota!.balance!, quota.currency)}'
        : hasQuotaApi
        ? '尚未查询额度'
        : '服务商控制台查询';
    final model = shortModelLabel(account.profile.model);
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      semanticLabel:
          '${account.descriptor.shortLabel}，${shortModelLabel(account.profile.model)}'
          '${active ? '，当前使用' : ''}，优先级 $priority，${accountStatusLabel(account, now)}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 3, 7),
        decoration: BoxDecoration(
          color: c.bgPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? c.accent : c.separator, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ProviderLogo(account.profile.product, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.descriptor.shortLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.footnote.copyWith(
                            fontWeight: FontWeight.w600,
                            color: c.labelPrimary,
                          ),
                        ),
                      ),
                      BillingMark(descriptor: account.descriptor),
                      Flexible(
                        child: Text(
                          model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Tooltip(
                    message: '当前使用',
                    child: Icon(
                      LucideIcons.check,
                      size: 14,
                      color: c.accentText,
                    ),
                  ),
                if (hasQuotaApi && account.hasCredential)
                  _IconAction(
                    icon: LucideIcons.refreshCw,
                    label: '刷新额度',
                    spinning: refreshing,
                    onTap: refreshing ? null : onRefresh,
                  ),
                _IconAction(
                  icon: LucideIcons.ellipsis,
                  label: '更多操作',
                  onTap: onMenu,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: SizedBox(
                height:
                    (MediaQuery.textScalerOf(context).scale(12) * 16 / 12)
                        .ceilToDouble() +
                    8,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: !unavailable && windows.isNotEmpty
                      ? Row(
                          children: [
                            Text(
                              '剩余',
                              style: AppTextStyles.caption.copyWith(
                                color: c.labelSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CompactQuotaWindows(windows: windows),
                            ),
                          ],
                        )
                      : Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: unavailable || (quota?.balance ?? 1) <= 0
                                ? c.red
                                : c.labelSecondary,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.spinning = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: label,
      child: AppPressable(
        onTap: onTap,
        semanticLabel: label,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: spinning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, size: 18, color: c.labelSecondary),
          ),
        ),
      ),
    );
  }
}
