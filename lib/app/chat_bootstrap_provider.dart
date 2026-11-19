import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/agent_run_store.dart';
import '../data/local/chat_persistence.dart';
import 'assist_provider.dart';
import 'model_settings_provider.dart';
import 'attachment_provider.dart';
import 'local_chat_runtime.dart';
import 'local_database_provider.dart';

/// Production always returns a real runtime. Null is an explicit fixture override,
/// never an error fallback or an empty seeded production database.
final localChatLoaderProvider = FutureProvider<LocalChatRuntime?>((ref) async {
  final db = await ref.watch(localDatabaseProvider.future);
  // 主应用和快捷面板同处一个进程。另一个引擎活着时，「生成中」的运行
  // 可能正由它驱动，不能当作上次进程遗留的来中断；留给 [EngineSync]
  // 在确认没有别的引擎后处理。
  if (!await ref.read(enginePeersProvider).othersAlive()) {
    await SqliteAgentRunStore(db).interruptAbandonedGenerations();
  }
  final snapshot = await ChatPersistence(db).load();
  final settings = await ref.watch(modelSettingsServiceProvider.future);
  final config = await db.readConfiguration();
  final accounts = await ref.watch(modelAccountServiceProvider.future);
  final runtime = LocalChatRuntime(
    db,
    settings,
    snapshot,
    config,
    attachments: () => ref.read(attachmentStoreProvider.future),
    accounts: accounts,
  );
  // FC4 promises startup attachment recovery; materialize the store now
  // instead of waiting for the first import or model request. Failure is
  // best-effort here: the import page surfaces it and offers a retry.
  unawaited(
    ref
        .read(attachmentStoreProvider.future)
        .then((_) {}, onError: (Object _) {}),
  );
  ref.onDispose(() => unawaited(runtime.dispose()));
  return runtime;
});
