import 'package:towork/l10n/strings.dart';

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

part 'model_account_card.dart';

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
      if (mounted) {
        AppToast.show(
          context,
          message: context.strings.couldntReadLocalSettingsTryAgain,
        );
      }
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
      if (mounted && !silent) {
        AppToast.show(context, message: context.strings.quotaUpdated);
      }
    } catch (error) {
      if (mounted && !silent) {
        AppToast.show(
          context,
          message:
              error is ModelFailure &&
                  error.code == ModelFailureCode.configuration
              ? context.strings.thisProviderDoesntOfferAQuotaApi
              : context.strings.couldntCheckQuota(
                  describeModelSettingsError(error),
                ),
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
      title: context.strings.deleteThisAccount,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${context.strings.theSettingsForAndTheKeySaved(account.descriptor.shortLabel)}'
              '${context.strings.permanentlyChatHistoryIsRetained}',
              style: AppTextStyles.body.copyWith(color: c.labelSecondary),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (sheet) => AppButton(
                key: const ValueKey('account-remove-confirm'),
                label: context.strings.deleteAccount,
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
    await _run(
      (service) => service.remove(account.id),
      done: context.strings.accountDeleted,
    );
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
                        context.strings.priorityOpenmenu(
                          index + 1,
                          account.autoRoute ? '' : context.strings.manualOnly,
                        ),
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
                    title: context.strings.useThisAccount,
                    onTap: () {
                      close();
                      _run(
                        (service) => service.activate(account.id),
                        done: context.strings.switchedToOpenmenu(
                          account.descriptor.shortLabel,
                        ),
                      );
                    },
                  ),
                SheetOptionRow(
                  icon: LucideIcons.pencilLine,
                  title: context.strings.editModelAndKey,
                  onTap: () {
                    close();
                    context.push(AppRoutes.modelAccount(account.id));
                  },
                ),
                if (account.descriptor.quota != QuotaSource.none &&
                    account.hasCredential)
                  SheetOptionRow(
                    icon: LucideIcons.refreshCw,
                    title: context.strings.refreshQuota,
                    onTap: () {
                      close();
                      _refresh(account);
                    },
                  ),
                if (account.coolingAt(DateTime.now().toUtc()))
                  SheetOptionRow(
                    icon: LucideIcons.timerReset,
                    title: context.strings.resumeAccount,
                    subtitle: context.strings.rejoinAutomaticFallback,
                    onTap: () {
                      close();
                      _run(
                        (service) => service.clearCooldown(account.id),
                        done: context.strings.accountResumed,
                      );
                    },
                  ),
                SheetOptionRow(
                  icon: account.autoRoute
                      ? LucideIcons.routeOff
                      : LucideIcons.route,
                  title: account.autoRoute
                      ? context.strings.excludeFromFallback
                      : context.strings.includeInFallback,
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
                    title: context.strings.increasePriority,
                    onTap: () {
                      close();
                      _move(snapshot, index, -1);
                    },
                  ),
                if (index < snapshot.accounts.length - 1)
                  SheetOptionRow(
                    icon: LucideIcons.arrowDown,
                    title: context.strings.decreasePriority,
                    onTap: () {
                      close();
                      _move(snapshot, index, 1);
                    },
                  ),
                SheetOptionRow(
                  icon: LucideIcons.trash2,
                  title: context.strings.deleteAccount,
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
              title: context.strings.modelsAndUsageBuild,
              actions: [
                if (snapshot != null)
                  WorkspaceToolbarGroup(
                    children: [
                      WorkspaceToolbarAction(
                        key: const ValueKey('account-add'),
                        label: context.strings.addModelAccount,
                        text: snapshot.accounts.isEmpty
                            ? context.strings.addBuild
                            : null,
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
                            context
                                .strings
                                .switchAccountsByPriorityWhenQuotaRuns,
                            style: AppTextStyles.caption.copyWith(
                              color: c.labelSecondary,
                            ),
                          ),
                          children: [
                            SettingsSwitchRow(
                              key: const ValueKey('auto-route-switch'),
                              title: context
                                  .strings
                                  .switchAutomaticallyWhenQuotaRunsOut,
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
                            context.strings.couldntReadLocalSettings,
                            style: AppTextStyles.body.copyWith(
                              color: c.labelSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.invalidate(modelAccountServiceProvider);
                              ref.invalidate(modelAccountsProvider);
                            },
                            child: Text(context.strings.retry),
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
