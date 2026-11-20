import 'package:towork/l10n/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_preferences_provider.dart';
import '../../../app/chat/chat_model_selection.dart';
import '../../../app/model_settings_provider.dart';
import '../../../app/navigation_requests.dart';
import '../../../app/local_chat_runtime.dart';
import '../../../app/routes.dart';
import '../../../app/workspace_state.dart';
import '../../../domain/ai/model_gateway.dart';
import '../../../domain/settings/model_account_service.dart';
import '../../../domain/settings/model_accounts.dart';
import '../../../core/ai/quota_widgets.dart';
import '../../../core/ai/brand_logos.dart';
import '../../../core/ai/model_identity.dart';
import '../../../core/widgets/app_anchored_popover.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'chat_model_picker_row.dart';

/// Both levels share one anchored surface. Browsing never changes the account.
Future<void> showChatModels(
  BuildContext context,
  WidgetRef ref, {
  GlobalKey? anchorKey,
}) {
  final demo = ref.read(localChatRuntimeProvider) == null;
  return AppAnchoredPopover.show<void>(
    context,
    anchorKey: anchorKey,
    maxWidth: 208,
    barrierColor: Colors.transparent,
    builder: (_) => _ModelSwitcherPopover(demo: demo),
  );
}

class _ModelSwitcherPopover extends ConsumerStatefulWidget {
  const _ModelSwitcherPopover({required this.demo});
  final bool demo;

  @override
  ConsumerState<_ModelSwitcherPopover> createState() =>
      _ModelSwitcherPopoverState();
}

class _ModelSwitcherPopoverState extends ConsumerState<_ModelSwitcherPopover> {
  ModelAccountService? _service;
  ProviderKind? _product;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.demo) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final service = await ref.read(modelAccountServiceProvider.future);
      if (mounted) setState(() => _service = service);
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.strings.couldntLoadModelSettings);
      }
    }
  }

  Future<void> _save(Future<void> Function() work, {bool close = true}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await work();
      if (mounted && close) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          message: error is ModelSelectionRestoreFailure
              ? context.strings.couldntSwitchModelsTurnAutomaticFallbackBack
              : context.strings.couldntSwitchTryAgainLater,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectAccount(ModelAccount account, String model) => _save(
    () => selectChatModel(
      accounts: _service!,
      preferences: ref.read(appPreferencesControllerProvider),
      accountId: account.id,
      model: model,
    ),
  );

  void _manage() {
    final router = GoRouter.maybeOf(context);
    final requests = ref.read(appNavigationRequestsProvider);
    Navigator.of(context).pop();
    if (router != null) {
      router.push(AppRoutes.modelAccounts);
    } else {
      requests.go(AppRoutes.modelAccounts);
    }
  }

  Widget _divider() => Divider(
    height: 5,
    indent: 6,
    endIndent: 6,
    color: AppColors.of(context).separator,
  );

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.demo ? null : ref.watch(modelAccountsProvider);
    final accounts = snapshot?.valueOrNull;
    final error =
        _error ??
        (snapshot?.hasError == true
            ? context.strings.couldntLoadModelSettings
            : null);
    final ready = widget.demo || (accounts != null && _service != null);
    final c = AppColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: GlassSurface(
        key: const ValueKey('model-picker'),
        radius: 14,
        padding: const EdgeInsets.all(4),
        child: !ready
            ? SizedBox(
                height: error == null ? 52 : null,
                child: Center(
                  heightFactor: 1,
                  child: error == null
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error, style: AppTextStyles.modelLabel),
                            TextButton(
                              onPressed: () {
                                ref.invalidate(modelAccountsProvider);
                                ref.invalidate(modelAccountServiceProvider);
                                _load();
                              },
                              child: Text(context.strings.retry),
                            ),
                          ],
                        ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_product == null)
                      ..._providers(accounts)
                    else ...[
                      ChatModelPickerRow(
                        key: const ValueKey('model-picker-back'),
                        label: productLabel(_product!),
                        leading: Icon(
                          LucideIcons.chevronLeft,
                          size: 16,
                          color: c.labelPrimary,
                        ),
                        semanticLabel: context.strings.backToProviders,
                        onTap: _saving
                            ? null
                            : () => setState(() => _product = null),
                      ),
                      _divider(),
                      if (widget.demo)
                        ..._demoModels()
                      else
                        ..._models(accounts!),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _providers(ModelAccountsSnapshot? snapshot) {
    final c = AppColors.of(context);
    final autoRoute = ref.watch(appPreferencesSnapshotProvider).autoRoute;
    final products = widget.demo
        ? {ProviderKind.moonshot}
        : {for (final account in snapshot!.accounts) account.profile.product};
    return [
      if (!widget.demo)
        ChatModelPickerRow(
          label: context.strings.automaticFallback,
          leading: Icon(LucideIcons.route, size: 16, color: c.labelPrimary),
          selected: autoRoute,
          onTap: _saving
              ? null
              : () => _save(() async {
                  await ref.read(appPreferencesControllerProvider).save({
                    'auto_route': true,
                  });
                }),
        ),
      for (final product in products)
        ChatModelPickerRow(
          key: ValueKey('provider-${product.wireId}'),
          label: productLabel(product),
          leading: BrandLogo(brand: brandOfProduct(product), size: 16),
          selected:
              widget.demo ||
              (!autoRoute && snapshot?.active?.profile.product == product),
          next: true,
          onTap: _saving ? null : () => setState(() => _product = product),
        ),
      if (!widget.demo) ...[
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              context.strings.addModelAccount,
              style: AppTextStyles.modelLabel.copyWith(color: c.labelSecondary),
            ),
          ),
        _divider(),
        ChatModelPickerRow(
          label: context.strings.manageAccounts,
          leading: Icon(
            LucideIcons.settings2,
            size: 16,
            color: c.labelSecondary,
          ),
          onTap: _saving ? null : _manage,
        ),
      ],
    ];
  }

  List<Widget> _models(ModelAccountsSnapshot snapshot) {
    final c = AppColors.of(context);
    final autoRoute = ref.watch(appPreferencesSnapshotProvider).autoRoute;
    final accounts = snapshot.accounts
        .where((a) => a.profile.product == _product)
        .toList();
    final active = snapshot.active;
    final now = DateTime.now().toUtc();
    return [
      for (final (index, account) in accounts.indexed) ...[
        if (accounts.length > 1 || accountNeedsAttention(account, now))
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${accounts.length > 1 ? context.strings.account(index + 1) : ''}${accountStatusLabel(account, now)}',
                style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
              ),
            ),
          ),
        // Include saved/custom/retired models so existing accounts stay usable.
        for (final model in {
          account.profile.model,
          ...account.descriptor.models.map((preset) => preset.id),
        })
          ChatModelPickerRow(
            key: ValueKey('model-${account.id}-$model'),
            label: account.descriptor.preset(model)?.label ?? model,
            leading: ProviderLogo(account.profile.product),
            semanticLabel: model,
            selected:
                !autoRoute &&
                snapshot.activeId == account.id &&
                account.profile.model == model,
            onTap: _saving || !account.hasCredential
                ? null
                : () => _selectAccount(account, model),
          ),
      ],
      if (active != null &&
          active.profile.product == _product &&
          active.descriptor.thinkingFor(active.profile.model) !=
              ThinkingControl.none) ...[
        _divider(),
        _thinkingRow(
          !active.profile.disableThinking,
          (value) => _save(() async {
            await _service!.save(
              id: active.id,
              profile: active.profile.copyWith(disableThinking: !value),
              activate: true,
            );
          }, close: false),
        ),
      ],
      if (accounts.isEmpty)
        ChatModelPickerRow(
          label: context.strings.accountRemovedGoBackAndChooseAnother,
          onTap: () => setState(() => _product = null),
        ),
    ];
  }

  List<Widget> _demoModels() => [
    for (final name in ['K3', context.strings.fast])
      ChatModelPickerRow(
        label: name == 'K3' ? 'Kimi K3' : name,
        leading: const ProviderLogo(ProviderKind.moonshot),
        selected: ref.watch(chatModelProvider) == name,
        onTap: () {
          ref.read(chatModelProvider.notifier).state = name;
          Navigator.of(context).pop();
        },
      ),
    _divider(),
    _thinkingRow(
      ref.watch(chatAdvancedProvider),
      (value) => ref.read(chatAdvancedProvider.notifier).state = value,
    ),
  ];

  Widget _thinkingRow(bool value, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            context.strings.deepThinking,
            style: AppTextStyles.modelLabel,
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.of(context).labelPrimary,
          onChanged: _saving ? null : onChanged,
        ),
      ],
    ),
  );
}
