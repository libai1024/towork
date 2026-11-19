import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/platform/assist_channel.dart';
import '../domain/assist/quick_assist.dart';
import 'engine_sync.dart';
import 'local_chat_runtime.dart';
import 'local_database_provider.dart';
import 'local_workspace_session.dart';
import 'navigation_requests.dart';
import 'routes.dart';
import 'workspace_state.dart';

final _assistChannelProvider = Provider<AssistChannel>((ref) {
  final channel = AssistChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

/// 快捷面板所在的窗口。只在面板引擎里有意义。
final assistHostProvider = Provider<AssistHost>(
  (ref) => ref.watch(_assistChannelProvider),
);

/// 设置页用来查看和配置各个唤起入口。
final assistEntriesProvider = Provider<AssistEntries>(
  (ref) => ref.watch(_assistChannelProvider),
);

final enginePeersProvider = Provider<EnginePeers>(
  (ref) => ref.watch(_assistChannelProvider),
);

/// 各入口当前的设置情况。用户可能刚从系统设置回来，所以不缓存：
/// 没人看时即释放，下次重新查询。
final assistEntryStatusProvider = FutureProvider.autoDispose<AssistEntryStatus>(
  (ref) => ref.watch(assistEntriesProvider).status(),
);

/// 工作区就绪后常驻，随前后台切换同步另一个引擎的提交。
final engineSyncProvider = Provider<EngineSync?>((ref) {
  final db = ref.watch(localDatabaseProvider).valueOrNull;
  final chat = ref.watch(localChatRuntimeProvider);
  final workspace = ref.watch(localWorkspaceSessionProvider);
  if (db == null || chat == null || workspace == null) return null;
  final sync = EngineSync(
    db: db,
    peers: ref.watch(enginePeersProvider),
    refresh: chat.refresh,
    busy: () => workspace.automaticWorkHeld,
    onHandoff: (handoff) {
      final session = handoff.sessionId;
      // 会话必须已经读进本引擎，否则选中它只会得到一个空白首页。
      if (session != null && chat.projection.sessionById(session) != null) {
        ref.read(currentSessionIdProvider.notifier).state = session;
      }
      ref
          .read(appNavigationRequestsProvider)
          .go(handoff.location ?? AppRoutes.home);
    },
  );
  final lifecycle = _SyncLifecycle(sync, WidgetsBinding.instance);
  ref.onDispose(() {
    lifecycle.dispose();
    sync.dispose();
  });
  return sync;
});

class _SyncLifecycle with WidgetsBindingObserver {
  _SyncLifecycle(this.sync, this.binding) {
    binding.addObserver(this);
    final state = binding.lifecycleState;
    if (state != null) didChangeAppLifecycleState(state);
  }
  final EngineSync sync;
  final WidgetsBinding binding;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => sync.setActive(
    state == AppLifecycleState.resumed || state == AppLifecycleState.inactive,
  );

  void dispose() => binding.removeObserver(this);
}
