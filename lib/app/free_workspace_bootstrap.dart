import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_button.dart';
import '../theme/app_theme.dart';
import 'local_database_provider.dart';
import 'app_preferences_provider.dart';
import 'assist_provider.dart';
import 'local_profile_provider.dart';
import 'local_workspace_session.dart';
import 'workspace_command_provider.dart';
import 'local_chat_runtime.dart';
import 'model_settings_provider.dart';
import 'chat_bootstrap_provider.dart';
import 'recurrence_window_provider.dart';
import 'notification_provider.dart';
import 'update/restart_readiness.dart';

/// Hydrates the real workspace before rendering pages that consume its profile.
/// A database failure offers recovery; it never invents a new empty identity.
class FreeWorkspaceBootstrap extends ConsumerStatefulWidget {
  const FreeWorkspaceBootstrap({
    super.key,
    required this.child,
    this.legacyInputMode = 'voice',
    this.placeholder,
  });
  final String legacyInputMode;
  final Widget child;

  /// 工作区就绪前显示的界面。[retry] 为空表示还在加载，非空表示打开
  /// 失败、可以重试。默认是全屏的加载/重试页；透明窗口（快捷面板）
  /// 需要换成自己的样子。
  final Widget Function(BuildContext context, VoidCallback? retry)? placeholder;
  @override
  ConsumerState<FreeWorkspaceBootstrap> createState() =>
      _FreeWorkspaceBootstrapState();
}

class _FreeWorkspaceBootstrapState
    extends ConsumerState<FreeWorkspaceBootstrap> {
  LocalWorkspaceSession? _workspace;
  LocalChatRuntime? _chat;
  bool _ready = false;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final store = await ref.read(localProfileStoreProvider.future);
      final profile = await store.loadOrCreateProfile();
      final commands = await ref.read(workspaceCommandStoreProvider.future);
      final snapshot = await commands.load();
      final preferencesStore = await ref.read(
        appPreferencesStoreProvider.future,
      );
      final preferences = await preferencesStore.loadOrCreate(
        legacyInputMode: widget.legacyInputMode,
      );
      final chat = await ref.read(localChatLoaderProvider.future);
      if (!mounted) return;
      ref.read(activePreferencesStoreProvider.notifier).state =
          preferencesStore;
      ref.read(appPreferencesSnapshotProvider.notifier).state = preferences;
      _workspace = LocalWorkspaceSession(commands, snapshot);
      _chat = chat;
      ref.read(localChatRuntimeProvider.notifier).state = _chat;
      ref.read(localWorkspaceSessionProvider.notifier).state = _workspace;
      ref.read(localProfileSnapshotProvider.notifier).state = profile;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      ref.invalidate(localDatabaseProvider);
      ref.invalidate(localProfileStoreProvider);
      ref.invalidate(workspaceCommandStoreProvider);
      ref.invalidate(appPreferencesStoreProvider);
      ref.invalidate(modelSettingsServiceProvider);
      ref.invalidate(localChatLoaderProvider);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    unawaited(_workspace?.dispose());
    unawaited(_chat?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      ref.watch(codeUpdateHostProvider);
      ref.watch(recurrenceWindowProvider);
      ref.watch(notificationCoordinatorProvider);
      ref.watch(engineSyncProvider);
      return widget.child;
    }
    final placeholder = widget.placeholder;
    if (placeholder != null) {
      return placeholder(context, _loading ? null : _load);
    }
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const CircularProgressIndicator.adaptive()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('暂时无法打开本地工作区。原有数据已保留，请重试。'),
                        const SizedBox(height: 20),
                        AppButton(label: '重新打开', onPressed: _load),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
