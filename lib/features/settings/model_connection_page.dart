import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/model_settings_provider.dart';
import '../../app/routes.dart';
import 'widgets/settings_input_field.dart';
import 'widgets/model_name_field.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/settings/model_account_service.dart';
import '../../domain/settings/model_accounts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../core/ai/model_failure_text.dart';
import 'widgets/settings_shared.dart';
import 'widgets/model_provider_fields.dart';
import 'widgets/model_action_button.dart';
import 'widgets/settings_editor_header.dart';

part 'model_connection_pickers.dart';

/// 模型账户编辑页：服务商、区域、模型、Key，以及保存前后的通断测试。
///
/// - [accountId] 指定要编辑的账户；
/// - [create] 为真时新建；
/// - 两者都没有时编辑当前账户，还没有任何账户则新建。
class ModelConnectionPage extends ConsumerStatefulWidget {
  const ModelConnectionPage({super.key, this.accountId, this.create = false});
  final String? accountId;
  final bool create;

  @override
  ConsumerState<ModelConnectionPage> createState() =>
      _ModelConnectionPageState();
}

class _ModelConnectionPageState extends ConsumerState<ModelConnectionPage> {
  final _model = TextEditingController();
  final _key = TextEditingController();
  final _baseUrl = TextEditingController();
  ModelAccountService? _service;

  /// 正在编辑的已保存账户；新建且尚未保存时为空。
  ModelAccount? _account;
  ProviderKind _product = ProviderKind.kimiCode;
  ProviderRegion _region = ProviderRegion.china;
  bool _loading = true;
  bool _loaded = false;
  bool _busy = false;
  bool _dirty = false;
  int _inputRevision = 0;
  int _credentialsRevision = 0;
  String? _feedback;
  VoidCallback? _dismissTestToast;
  ModelCancellation? _cancellation;

  ProviderDescriptor get _descriptor => ProviderCatalog.of(_product);
  bool get _fieldsEnabled => !_busy || _cancellation != null;
  bool get _endpointUnchanged {
    final saved = _account?.profile;
    return saved != null &&
        saved.product == _product &&
        saved.region == _region &&
        (saved.baseUrl ?? '') ==
            (_descriptor.needsBaseUrl ? _baseUrl.text.trim() : '');
  }

  bool get _canFetch {
    final endpoint = Uri.tryParse(_baseUrl.text.trim());
    final validEndpoint =
        !_descriptor.needsBaseUrl ||
        (endpoint != null &&
            endpoint.scheme == 'https' &&
            endpoint.host.isNotEmpty &&
            endpoint.userInfo.isEmpty);
    return validEndpoint &&
        _loaded &&
        (_key.text.trim().isNotEmpty ||
            (_account?.hasCredential == true && _endpointUnchanged));
  }

  bool get _canTest => _canFetch && _model.text.trim().isNotEmpty;

  Future<List<String>> _fetchModels(ModelCancellation cancellation) =>
      _service!.availableModels(
        id: _account?.id,
        product: _product,
        region: _region,
        baseUrl: _descriptor.needsBaseUrl ? _baseUrl.text.trim() : null,
        key: _key.text,
        cancellation: cancellation,
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _dismissTestToast?.call();
    _cancellation?.cancel();
    _model.dispose();
    _key.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _feedback = null;
    });
    try {
      final service = await ref.read(modelAccountServiceProvider.future);
      final snapshot = await service.load();
      if (!mounted) return;
      _service = service;
      final target = widget.create
          ? null
          : widget.accountId != null
          ? snapshot.byId(widget.accountId!)
          : snapshot.active;
      _accept(target);
    } catch (error) {
      if (mounted) {
        if (_service == null) {
          ref.invalidate(modelSettingsServiceProvider);
          ref.invalidate(modelAccountServiceProvider);
        }
        setState(() => _feedback = describeModelSettingsError(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _accept(ModelAccount? account) {
    setState(() {
      _loaded = true;
      _account = account;
      if (account != null) {
        _product = account.profile.product;
        _region = account.profile.region;
        _model.text = account.profile.model;
        _baseUrl.text = account.profile.baseUrl ?? '';
      } else {
        _model.text = _descriptor.models.firstOrNull?.id ?? '';
        _baseUrl.clear();
      }
      _credentialsRevision++;
      _key.clear();
      _dirty = false;
    });
  }

  void _edited({bool credentials = false}) => setState(() {
    _dismissTestToast?.call();
    if (credentials) _credentialsRevision++;
    _cancellation?.cancel();
    _inputRevision++;
    _dirty = true;
    _feedback = null;
  });

  ModelProfile _draft() => ModelProfile(
    model: _model.text.trim(),
    product: _product,
    region: _region,
    disableThinking: _account?.profile.disableThinking ?? true,
    baseUrl: _descriptor.needsBaseUrl ? _baseUrl.text.trim() : null,
  );

  Future<void> _save() async {
    final service = _service;
    if (_busy || service == null) return;
    _dismissTestToast?.call();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final creating = _account == null;
      final before = creating ? await service.load() : null;
      final snapshot = await service.save(
        id: _account?.id,
        profile: _draft(),
        newKey: _key.text.isEmpty ? null : _key.text,
        // 新添加的账户立即成为当前账户：加完就能用。
        activate: creating,
      );
      if (!mounted) return;
      final known = {
        for (final a in before?.accounts ?? const <ModelAccount>[]) a.id,
      };
      final saved = creating
          ? snapshot.accounts.where((a) => !known.contains(a.id)).firstOrNull
          : snapshot.byId(_account!.id);
      _accept(saved);
      if (ModalRoute.of(context)?.isCurrent == true) {
        await Navigator.of(context).maybePop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _feedback = describeModelSettingsError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final service = _service;
    if (_busy || !_canTest || service == null) return;
    _dismissTestToast?.call();
    final inputRevision = _inputRevision;
    final isDraft = _dirty || _account == null;
    final cancellation = ModelCancellation();
    final clock = Stopwatch()..start();
    setState(() {
      _busy = true;
      _cancellation = cancellation;
    });
    try {
      final result = isDraft
          ? await service.testDraft(
              id: _account?.id,
              profile: _draft(),
              cancellation: cancellation,
              key: _key.text.isEmpty ? null : _key.text,
            )
          : await service.test(_account!.id, cancellation);
      if (!mounted || inputRevision != _inputRevision) return;
      final tokens = result.usage?['total_tokens'];
      _showTestResult(
        '${isDraft ? context.strings.connectedUnsaved : context.strings.connected} ${clock.elapsedMilliseconds} ms'
        '${tokens is num ? ' $tokens tokens' : ''}',
      );
    } catch (error) {
      if (mounted && inputRevision == _inputRevision) {
        _showTestResult(describeModelSettingsError(error));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _cancellation = null;
        });
      }
    }
  }

  void _showTestResult(String message) {
    if (ModalRoute.of(context)?.isCurrent == false) return;
    _dismissTestToast = AppToast.showCentered(context, message);
  }

  void _selectProduct(ProviderKind product) {
    if (_product == product) return;
    _dismissTestToast?.call();
    setState(() {
      _product = product;
      _model.text = _descriptor.models.firstOrNull?.id ?? '';
      // Key 不跟随到另一个服务商。
      _key.clear();
      _cancellation?.cancel();
      _inputRevision++;
      _dirty = true;
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final descriptor = _descriptor;
    return Material(
      key: const ValueKey('model-account-sheet'),
      color: c.bgGround,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsEditorHeader(
              handleKey: const ValueKey('model-sheet-header'),
              saveKey: const ValueKey('model-save'),
              saveLabel: context.strings.save,
              title: _account != null || widget.accountId != null
                  ? context.strings.editModelAccount
                  : context.strings.addModelAccount,
              onClose: () => context.popOrGo(AppRoutes.modelAccounts),
              saving: _busy && _cancellation == null,
              onSave: _loaded && _dirty && !_busy && _canTest ? _save : null,
            ),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                          children: [
                            if (_loaded) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: c.bgPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    ModelProviderField(
                                      descriptor: descriptor,
                                      enabled: _fieldsEnabled,
                                      onTap: _pickProduct,
                                    ),
                                    if (descriptor.regional)
                                      SettingsRow(
                                        title: context.strings.serviceRegion,
                                        value: _region == ProviderRegion.china
                                            ? context.strings.china
                                            : context.strings.international,
                                        showChevron: true,
                                        enabled: _fieldsEnabled,
                                        onTap: _pickRegion,
                                      ),
                                  ],
                                ),
                              ),
                              if (descriptor.needsBaseUrl) ...[
                                const SizedBox(height: 8),
                                SettingsInputField(
                                  fieldKey: const ValueKey(
                                    'custom-base-url-input',
                                  ),
                                  label: context.strings.apiEndpoint,
                                  hint: 'https://example.com/v1',
                                  controller: _baseUrl,
                                  enabled: _fieldsEnabled,
                                  maxLength: 200,
                                  keyboardType: TextInputType.url,
                                  onChanged: (_) {
                                    _key.clear();
                                    _edited(credentials: true);
                                  },
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SettingsInputField(
                                      fieldKey: const ValueKey(
                                        'model-key-input',
                                      ),
                                      label: 'API Key',
                                      hint:
                                          _account?.hasCredential == true &&
                                              _endpointUnchanged
                                          ? context
                                                .strings
                                                .savedLeaveBlankToKeep
                                          : context.strings.enterKey,
                                      controller: _key,
                                      secret: true,
                                      enabled: _fieldsEnabled,
                                      onChanged: (_) =>
                                          _edited(credentials: true),
                                    ),
                                  ),
                                  ModelActionButton(
                                    key: const ValueKey('model-test'),
                                    label: _cancellation != null
                                        ? context.strings.cancelTest
                                        : context.strings.testConnection,
                                    icon: _cancellation != null
                                        ? LucideIcons.square
                                        : LucideIcons.plug,
                                    onPressed: _cancellation != null
                                        ? _cancellation!.cancel
                                        : !_busy && _canTest
                                        ? _test
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ModelNameField(
                                key: ValueKey(_product),
                                descriptor: descriptor,
                                controller: _model,
                                enabled: _fieldsEnabled,
                                onChanged: _edited,
                                load: _canFetch && !_busy ? _fetchModels : null,
                                credentialsRevision: _credentialsRevision,
                              ),
                              if (descriptor.notice != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ModelProviderNotice(
                                    text: descriptor.notice!,
                                  ),
                                ),
                            ],
                            if (_feedback != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _feedback!,
                                    key: const ValueKey('model-feedback'),
                                    style: AppTextStyles.body.copyWith(
                                      color: c.labelPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            if (!_loaded)
                              Center(
                                child: TextButton(
                                  onPressed: _busy ? null : _load,
                                  child: Text(context.strings.reloadBuild),
                                ),
                              ),
                          ],
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
