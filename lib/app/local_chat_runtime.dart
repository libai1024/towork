import '../agent/tools/question_tool.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../agent/agent_runner.dart';
import '../data/local/agent_run_store.dart';
import '../data/local/attachment_store.dart';
import '../data/local/agent_tool_executor.dart';
import '../data/local/app_database.dart';
import '../data/local/chat_persistence.dart';
import '../data/local/model_account_store.dart';
import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/chat/local_chat.dart';
import '../domain/models/chat.dart';
import '../domain/repositories/chat_store.dart';
import '../domain/settings/model_account_service.dart';
import '../domain/settings/model_settings.dart';
import '../domain/settings/model_settings_service.dart';

final localChatRuntimeProvider = StateProvider<LocalChatRuntime?>(
  (ref) => null,
);
final liveChatConfigurationProvider = StreamProvider<ModelConfiguration>((ref) {
  final runtime = ref.watch(localChatRuntimeProvider);
  return runtime?.configurations ?? const Stream.empty();
});

class LocalChatProjection extends ChatStore {
  LocalChatProjection() : super([]);
  LocalChatSnapshot data = LocalChatSnapshot([], []);
  final Map<String, List<ChatMessage>> _messages = {};
  @override
  List<ChatMessage> messagesOf(String sessionId) =>
      List.unmodifiable(_messages[sessionId] ?? []);
  @override
  ChatSession? sessionById(String? id) =>
      state.where((s) => s.id == id).firstOrNull;
  @override
  ChatMessage? messageById(String? id) =>
      _messages.values.expand((m) => m).where((m) => m.id == id).firstOrNull;
  LocalChatTurn? turn(String runId) =>
      data.turns.where((t) => t.run.id == runId).firstOrNull;
  LocalConversation? conversation(String id) =>
      data.conversations.where((s) => s.id == id).firstOrNull;
  void accept(LocalChatSnapshot value) {
    if (!mounted) return;
    final sessions = {for (final s in data.conversations) s.id: s};
    final turns = {for (final t in data.turns) t.inputId: t};
    for (final s in value.conversations) {
      if ((sessions[s.id]?.revision ?? 0) <= s.revision) sessions[s.id] = s;
    }
    for (final t in value.turns) {
      final old = turns[t.inputId];
      if (old == null ||
          t.run.revision > old.run.revision ||
          (t.run.revision == old.run.revision &&
              (old.undoneAt == null || t.undoneAt != null))) {
        turns[t.inputId] = t;
      }
    }
    data = LocalChatSnapshot(sessions.values, turns.values);
    _messages.clear();
    final projected = <ChatSession>[];
    for (final s in sessions.values.where((s) => s.deletedAt == null)) {
      final ordered = turns.values.where((t) => t.sessionId == s.id).toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      final messages = ordered.expand((t) => t.messages).toList();
      _messages[s.id] = messages;
      projected.add(
        ChatSession(
          id: s.id,
          title: s.title,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
          modelId: ordered.lastOrNull?.run.profile.model ?? '',
          lastMessagePreview:
              messages
                  .where((m) => m.type == ChatMessageType.text)
                  .lastOrNull
                  ?.content ??
              '',
        ),
      );
    }
    projected.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = projected;
  }

  Never _readonly() => throw StateError('Use awaited chat commands');
  @override
  ChatSession createSession() => _readonly();
  @override
  void appendMessage(ChatMessage message) => _readonly();
  @override
  void insertMessageAt(int index, ChatMessage message) => _readonly();
  @override
  void updateMessage(ChatMessage message) => _readonly();
  @override
  void removeMessage(String sessionId, String messageId) => _readonly();
  @override
  String nextMessageId() => _readonly();
  @override
  void renameSession(String id, String title) => _readonly();
}

class LocalChatRuntime {
  LocalChatRuntime(
    this.db,
    this.settings,
    LocalChatSnapshot initial,
    this.initialConfiguration, {
    this.attachments,
    ModelAccountService? accounts,
  }) : persistence = ChatPersistence(db),
       runs = SqliteAgentRunStore(db),
       accounts =
           accounts ??
           ModelAccountService(settings, SqliteModelAccountStore(db)) {
    projection.accept(initial);
    _subscription = persistence.watch().listen(
      (value) {
        readError = null;
        projection.accept(value);
      },
      onError: (Object error) {
        readError = error;
        projection.accept(projection.data);
      },
    );
  }
  final AppDatabase db;
  final ModelSettingsService settings;

  /// 多账户与路由。测试可注入带额度网关的实现。
  final ModelAccountService accounts;
  final ModelConfiguration initialConfiguration;
  final Future<AttachmentStore> Function()? attachments;
  final ChatPersistence persistence;
  final SqliteAgentRunStore runs;
  final projection = LocalChatProjection();
  StreamSubscription<LocalChatSnapshot>? _subscription;
  Object? readError;
  bool _disposed = false;
  Stream<ModelConfiguration> get configurations => db
      .select(db.providerConfigurations)
      .watch()
      .asyncMap((_) => db.readConfiguration());
  Future<void> refresh() async {
    try {
      final snapshot = await persistence.load();
      if (!_disposed) {
        readError = null;
        projection.accept(snapshot);
      }
    } catch (error) {
      if (!_disposed) {
        readError = error;
        projection.accept(projection.data);
      }
      rethrow;
    }
  }

  AgentRunner runner(bool agentEnabled, {void Function(int)? onRoundStart}) {
    final executor = SqliteAgentToolExecutor(
      db,
      requireCurrentConfiguration: true,
    );
    return AgentRunner(
      gateway: _ConfiguredGateway(settings, attachments),
      store: runs,
      tools: agentEnabled ? executor : _ChatOnlyTools(executor),
      // 参数写错或版本过期时让模型自己改两次，而不是让用户重说。
      maxCorrections: agentEnabled ? 2 : 0,
      onRoundStart: onRoundStart,
    );
  }

  /// 把失败的运行改绑到给定配置，供「换模型重试」与自动换用使用。
  Future<AgentRun> rebind(AgentRun run, ModelProfile profile) =>
      runs.rebind(run.id, expectedRevision: run.revision, profile: profile);

  Future<AgentRun> refreshProposal(
    String id, {
    required int expectedRevision,
  }) =>
      SqliteAgentToolExecutor(db)
          .refreshProposal(id, expectedRevision: expectedRevision);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription?.cancel();
  }
}

class _ConfiguredGateway implements ModelGateway {
  const _ConfiguredGateway(this.settings, this.attachments);
  final ModelSettingsService settings;
  final Future<AttachmentStore> Function()? attachments;
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    final config = await settings.store.readConfiguration();
    if (config.version != request.profile.revision ||
        config.credentialRef == null ||
        config.profile.model != request.profile.model ||
        config.profile.product != request.profile.product ||
        config.profile.region != request.profile.region) {
      throw const ModelFailure(ModelFailureCode.configuration);
    }
    var outgoing = request;
    if (request.messages.any((m) => m['_towork_attachment_id'] != null)) {
      if (attachments == null) {
        throw const ModelFailure(ModelFailureCode.configuration);
      }
      outgoing = await (await attachments!()).hydrate(request);
    }
    if (cancellation?.isCancelled ?? false) {
      throw const ModelFailure(ModelFailureCode.cancelled);
    }
    yield* settings.gateway.stream(
      outgoing,
      apiKey: apiKey,
      cancellation: cancellation,
    );
  }
}

/// Chat-only mode can ask questions while keeping workspace tools unavailable.
class _ChatOnlyTools implements AgentToolExecutor {
  _ChatOnlyTools(this.delegate);
  final AgentToolExecutor delegate;
  @override
  List<JsonObject> get schemas => [const QuestionTool().schema];
  @override
  Future<AgentRun> propose(AgentRun run, ModelCompleted completion) {
    final calls = completion.assistantMessage['tool_calls'];
    if (calls is! List ||
        calls.any(
          (call) =>
              call is! Map ||
              call['function'] is! Map ||
              call['function']['name'] != 'show_question',
        )) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    return delegate.propose(run, completion);
  }

  @override
  Future<AgentRun> execute(
    AgentRun run, {
    AgentApproval? approval,
    ModelCancellation? cancellation,
  }) {
    final calls = run.proposal?['calls'];
    if (calls is! List ||
        calls.any((call) => call is! Map || call['name'] != 'show_question')) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    return delegate.execute(
      run,
      approval: approval,
      cancellation: cancellation,
    );
  }
}
