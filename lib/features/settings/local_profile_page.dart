import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/local_profile_provider.dart';
import '../../app/routes.dart';
import '../../core/widgets/workspace_nav_bar.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'widgets/settings_input_field.dart';
import '../../domain/settings/local_profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/settings_editor_header.dart';

class LocalProfilePage extends ConsumerStatefulWidget {
  const LocalProfilePage({super.key});
  @override
  ConsumerState<LocalProfilePage> createState() => _LocalProfilePageState();
}

class _LocalProfilePageState extends ConsumerState<LocalProfilePage> {
  final _name = TextEditingController();
  LocalProfileStore? _store;
  LocalProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _feedback;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
      _feedback = null;
    });
    try {
      final store = await ref.read(localProfileStoreProvider.future);
      final profile = await store.loadOrCreateProfile();
      if (!mounted) return;
      _store = store;
      _accept(profile);
    } catch (error) {
      if (mounted) {
        ref.invalidate(localProfileStoreProvider);
        setState(() {
          _failed = true;
          _feedback = _message(error);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _accept(LocalProfile profile) {
    ref.read(localProfileSnapshotProvider.notifier).state = profile;
    setState(() {
      _profile = profile;
      _name.text = profile.nickname;
    });
  }

  Future<void> _save() async {
    if (_saving || _profile == null) return;
    final projection = ref.read(localProfileSnapshotProvider.notifier);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _failed = false;
      _feedback = null;
    });
    try {
      final profile = await _store!.renameProfile(
        _name.text,
        expectedVersion: _profile!.version,
      );
      // Keep other pages consistent even if this page was closed during commit.
      if (projection.mounted) projection.state = profile;
      if (!mounted) return;
      _accept(profile);
      setState(() => _feedback = '用户名已保存到此设备');
    } catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _feedback = _message(error);
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _message(Object error) => switch (error) {
    ProfileFailure(code: ProfileFailureCode.invalidName) =>
      '用户名需要 1–40 个字符，不能包含换行或控制字符',
    ProfileFailure(code: ProfileFailureCode.conflict) => '资料已变化，请重新载入后再保存',
    _ => '本地资料暂时无法读取或保存，请重试',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.bgGround,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SettingsEditorHeader(
              title: '个人资料',
              onClose: () => context.popOrGo(AppRoutes.settings),
              saveKey: const ValueKey('save-local-profile'),
              saveLabel: '保存用户名',
              saving: _saving,
              onSave:
                  _profile != null &&
                      !_loading &&
                      !_saving &&
                      _name.text != _profile!.nickname
                  ? _save
                  : null,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_loading)
                      const Center(child: CircularProgressIndicator.adaptive())
                    else if (_profile != null)
                      SettingsInputField(
                        fieldKey: const ValueKey('local-nickname-input'),
                        label: '用户名',
                        hint: '输入用户名',
                        controller: _name,
                        enabled: !_saving,
                        maxLength: 40,
                        onChanged: (_) => setState(() {
                          if (!_failed) _feedback = null;
                        }),
                        onSubmitted: (_) => _save(),
                      ),
                    if (_feedback != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _feedback!,
                            style: AppTextStyles.footnote.copyWith(
                              color: c.labelSecondary,
                            ),
                          ),
                        ),
                      ),
                    if (_failed)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: WorkspaceToolbarAction(
                          icon: LucideIcons.rotateCw,
                          label: '重新载入',
                          text: '重新载入',
                          onTap: _saving ? null : _load,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
