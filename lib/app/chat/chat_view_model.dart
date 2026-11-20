import 'package:towork/l10n/strings.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_preferences_provider.dart';
import '../dependencies.dart';
import '../workspace_state.dart';
import '../providers.dart';
import '../workspace_ui_commands.dart';
import '../local_chat_runtime.dart';
import '../local_workspace_session.dart';
import '../../domain/ai/agent_run.dart';
import 'live_chat_view_model.dart';
import '../../domain/repositories/chat_gateway.dart';
import '../../domain/models/models.dart';

class ChatGenerationState {
  const ChatGenerationState({
    this.isGenerating = false,
    this.messageId,
    this.error,
    this.sessionId,
    this.runId,
    this.streamingText = '',
    this.isSavingInput = false,
    this.notice,
  });
  final bool isGenerating;
  final String? messageId;
  final Object? error;
  final String? sessionId, runId;
  final String streamingText;
  final bool isSavingInput;

  /// 需要让用户知道、但不是错误的事件（例如自动换用了另一个模型）。
  final String? notice;
}

enum ChatTodoRestoreResult { restored, conflict, unavailable }

/// A single restoration attempt issued by the controller that removed the task.
class ChatTodoUndo {
  ChatTodoUndo._(
    this.card,
    this.todo,
    this.messageIndex,
    this._todoIndex,
    this._owner,
  );
  final ChatMessage card;
  final Todo todo;
  final int messageIndex;
  final int _todoIndex;
  final Object _owner;
  bool _used = false;
  UiWorkspaceChange<void>? _persistentChange;
}

class _ChatRequest {
  const _ChatRequest(this.message, this.model, this.agentEnabled);
  final ChatMessage message;
  final String model;
  final bool agentEnabled;
}

/// Shared for the workspace lifetime. Navigating to another tool may keep a
/// reply running, but selecting another conversation explicitly cancels it.
final chatViewModelProvider =
    StateNotifierProvider<ChatViewModel, ChatGenerationState>((ref) {
      final runtime = ref.watch(localChatRuntimeProvider);
      final controller = runtime == null
          ? ChatViewModel(
              chats: ref.watch(sessionListProvider.notifier),
              todos: ref.watch(todoListProvider.notifier),
              gateway: ref.watch(chatGatewayProvider),
              workspace: ref.watch(workspaceUiCommandsProvider),
              currentSession: () => ref.read(currentSessionIdProvider),
              selectSession: (id) =>
                  ref.read(currentSessionIdProvider.notifier).state = id,
            )
          : LiveChatViewModel(
              runtime: runtime,
              localWorkspace: ref.watch(localWorkspaceSessionProvider),
              autoRoute: () =>
                  ref.read(appPreferencesSnapshotProvider).autoRoute,
              todos: ref.watch(todoListProvider.notifier),
              currentSession: () => ref.read(currentSessionIdProvider),
              selectSession: (id) =>
                  ref.read(currentSessionIdProvider.notifier).state = id,
            );
      ref.listen(currentSessionIdProvider, (previous, next) {
        if (previous != next) controller.cancel();
      });
      return controller;
    });

/// Owns generation, cancellation and cross-repository task creation. Rendering,
/// text controllers, navigation, haptics and scrolling remain in the view.
class ChatViewModel extends StateNotifier<ChatGenerationState> {
  ChatViewModel({
    required this._chats,
    required this._todos,
    required this._gateway,
    required this._currentSession,
    required this._selectSession,
    DateTime Function()? clock,
    this.workspace,
    this.responseDelay = const Duration(seconds: 1),
    this.tokenInterval = const Duration(milliseconds: 30),
  }) : _clock = clock ?? DateTime.now,
       super(const ChatGenerationState());

  final WorkspaceUiCommands? workspace;
  final ChatStore _chats;
  final TodoReadStore _todos;
  TodoStore get _memoryTodos {
    final todos = _todos;
    if (todos is TodoStore) return todos;
    throw StateError('Synchronous chat edits require an in-memory store');
  }

  final ChatGateway _gateway;
  final String? Function() _currentSession;
  final void Function(String) _selectSession;
  final DateTime Function() _clock;
  final Duration responseDelay;
  final Duration tokenInterval;
  Timer? _responseTimer;
  Timer? _streamTimer;
  String? _sessionId;
  int _request = 0;
  _ChatRequest? _activeRequest;
  _ChatRequest? _failedRequest;
  final Object _undoOwner = Object();

  ChatGenerationState get snapshot => state;

  Future<bool> sendPersisted(
    String input, {
    required String model,
    bool agentEnabled = true,
    String? inputId,
    String? attachmentId,
    String? replyToInputId,
    bool fromVoice = false,
  }) async => send(input, model: model, agentEnabled: agentEnabled);
  Future<void> renameSessionPersisted(String id, String title) async =>
      _chats.renameSession(id, title);
  Future<void> deleteSessionPersisted(String id) async =>
      _chats.deleteSession(id);
  Future<void> resumeRun(
    String id, {
    AgentApproval? approval,
    bool retry = false,
  }) async => throw UnsupportedError('Persistent Agent required');
  Future<void> cancelRun(String id) async =>
      throw UnsupportedError('Persistent Agent required');
  Future<void> undoRun(String id) async =>
      throw UnsupportedError('Persistent Agent required');
  Future<void> refreshRunProposal(String id) async =>
      throw UnsupportedError('Persistent Agent required');

  bool send(String input, {required String model, bool agentEnabled = true}) {
    final text = input.trim();
    if (!mounted || state.isGenerating || text.isEmpty) return false;
    var sessionId = _currentSession();
    if (_chats.sessionById(sessionId) == null) {
      final session = _chats.createSession();
      sessionId = session.id;
      final runes = text.runes.toList();
      _chats.renameSession(
        session.id,
        runes.length > 12 ? '${String.fromCharCodes(runes.take(12))}…' : text,
      );
      _selectSession(session.id);
    }
    _sessionId = sessionId!;
    final userMessage = ChatMessage(
      id: _chats.nextMessageId(),
      sessionId: sessionId,
      role: ChatRole.user,
      type: ChatMessageType.text,
      content: text,
      createdAt: _clock(),
    );
    _chats.appendMessage(userMessage);
    _start(_ChatRequest(userMessage, model, agentEnabled));
    return true;
  }

  void _start(_ChatRequest details) {
    _activeRequest = details;
    _failedRequest = null;
    final request = ++_request;
    state = const ChatGenerationState(isGenerating: true);
    unawaited(
      _prepare(request, details.message, details.model, details.agentEnabled),
    );
  }

  /// Reuses the failed user message, avoiding duplicate sends in history.
  bool retry() {
    if (!mounted || state.isGenerating) return false;
    final failed = _failedRequest;
    if (failed == null || failed.message.sessionId != _currentSession()) {
      return false;
    }
    _start(failed);
    return true;
  }

  bool _isActive(int request) =>
      mounted && request == _request && state.isGenerating;

  Future<void> _prepare(
    int request,
    ChatMessage userMessage,
    String model,
    bool agentEnabled,
  ) async {
    try {
      final parsed = await _gateway.respond(userMessage.content);
      if (!_isActive(request)) return;
      if (parsed.text.trim().isEmpty) {
        throw StateError('The assistant returned an empty reply.');
      }
      final reply = !agentEnabled && parsed.draft != null
          ? ChatReply(text: strings.thisCanBeSplitIntoThreeSteps)
          : parsed;
      _responseTimer = Timer(responseDelay, () {
        if (!_isActive(request)) return;
        try {
          final message = ChatMessage(
            id: _chats.nextMessageId(),
            sessionId: userMessage.sessionId,
            role: ChatRole.assistant,
            type: ChatMessageType.text,
            content: '',
            createdAt: _clock(),
            modelId: model,
          );
          _chats.appendMessage(message);
          state = ChatGenerationState(
            isGenerating: true,
            messageId: message.id,
          );
          _stream(request, userMessage, message, reply);
        } catch (error) {
          _fail(request, error);
        }
      });
    } catch (error) {
      _fail(request, error);
    }
  }

  void _stream(
    int request,
    ChatMessage user,
    ChatMessage message,
    ChatReply reply,
  ) {
    final runes = reply.text.runes.toList();
    var end = 0;
    _streamTimer = Timer.periodic(tokenInterval, (timer) async {
      if (!_isActive(request)) {
        timer.cancel();
        return;
      }
      try {
        if (_chats.messageById(message.id) == null) {
          cancel();
          return;
        }
        if (end < runes.length) {
          end = (end + 2).clamp(0, runes.length);
          _chats.updateMessage(
            message.copyWith(content: String.fromCharCodes(runes.take(end))),
          );
          return;
        }
        timer.cancel();
        final draft = reply.draft;
        if (draft != null) {
          UiWorkspaceChange<Todo>? change;
          final Todo todo;
          if (workspace case final commands?) {
            change = await commands.appendTodo(
              title: draft.title,
              dueAt: draft.dueAt,
              categoryId: draft.categoryId,
              source: TodoSource.ai,
              sourceMessageId: user.id,
            );
            todo = change.value;
          } else {
            todo = _memoryTodos.addTodo(
              title: draft.title,
              dueAt: draft.dueAt,
              categoryId: draft.categoryId,
              source: TodoSource.ai,
              sourceMessageId: user.id,
            );
          }
          try {
            _chats.appendMessage(
              ChatMessage(
                id: _chats.nextMessageId(),
                sessionId: user.sessionId,
                role: ChatRole.assistant,
                type: ChatMessageType.todoCard,
                content: '',
                createdAt: _clock(),
                todoId: todo.id,
              ),
            );
          } catch (_) {
            if (change != null) {
              await change.undo();
            } else {
              _memoryTodos.removeById(todo.id);
            }
            rethrow;
          }
        }
        if (_isActive(request)) state = const ChatGenerationState();
      } catch (error) {
        _fail(request, error);
      }
    });
  }

  void _fail(int request, Object error) {
    if (!_isActive(request)) return;
    final failed = _activeRequest;
    cancel();
    _failedRequest = failed;
    state = ChatGenerationState(error: error);
  }

  void cancel() {
    if (!mounted) return;
    _request++;
    _responseTimer?.cancel();
    _streamTimer?.cancel();
    final message = _chats.messageById(state.messageId);
    if (message != null && message.sessionId == _sessionId) {
      if (message.content.isEmpty) {
        _chats.removeMessage(message.sessionId, message.id);
      } else {
        _chats.updateMessage(message.copyWith(stoppedByUser: true));
      }
    }
    _activeRequest = null;
    _failedRequest = null;
    state = const ChatGenerationState();
  }

  Future<ChatTodoUndo> undoTodoPersisted(ChatMessage card, Todo todo) async {
    final commands = workspace;
    if (commands == null) return undoTodo(card, todo);
    final current = _chats.messageById(card.id);
    final task = _todos.byId(todo.id);
    if (current == null ||
        task == null ||
        current.todoId != task.id ||
        current.sessionId != card.sessionId) {
      throw RepositoryException(
        RepositoryErrorCode.conflict,
        strings.theTaskOrItsCardHasChanged,
      );
    }
    final index = _chats
        .messagesOf(card.sessionId)
        .indexWhere((e) => e.id == card.id);
    final change = await commands.run<void>((t, c) => t.removeById(task.id));
    try {
      _chats.removeMessage(card.sessionId, card.id);
    } catch (_) {
      await change.undo();
      rethrow;
    }
    return ChatTodoUndo._(current, task, index, 0, _undoOwner)
      .._persistentChange = change;
  }

  Future<ChatTodoRestoreResult> restoreTodoPersisted(ChatTodoUndo undo) async {
    final change = undo._persistentChange;
    if (change == null) return restoreTodo(undo);
    if (undo._used || !identical(undo._owner, _undoOwner) || !_chats.mounted) {
      return ChatTodoRestoreResult.unavailable;
    }
    if (_chats.messageById(undo.card.id) != null ||
        _chats.sessionById(undo.card.sessionId) == null) {
      return ChatTodoRestoreResult.conflict;
    }
    await change.undo();
    _chats.insertMessageAt(undo.messageIndex, undo.card);
    undo._used = true;
    return ChatTodoRestoreResult.restored;
  }

  ChatTodoUndo undoTodo(ChatMessage card, Todo todo) {
    if (!mounted || !_chats.mounted || !_todos.mounted) {
      throw RepositoryException(
        RepositoryErrorCode.conflict,
        strings.thisChatIsClosedItsTaskCan,
      );
    }
    final currentCard = _chats.messageById(card.id);
    final currentTodo = _todos.byId(todo.id);
    if (currentCard == null || currentTodo == null) {
      throw RepositoryException(
        RepositoryErrorCode.notFound,
        strings.theTaskOrItsCardNoLonger,
      );
    }
    if (currentCard.type != ChatMessageType.todoCard ||
        currentCard.todoId != currentTodo.id ||
        currentCard.sessionId != card.sessionId ||
        _chats.sessionById(currentCard.sessionId) == null) {
      throw RepositoryException(
        RepositoryErrorCode.conflict,
        strings.theCardNowLinksToADifferent,
      );
    }
    final index = _chats
        .messagesOf(currentCard.sessionId)
        .indexWhere((m) => m.id == currentCard.id);
    final todoIndex = _todos.snapshot.indexWhere((t) => t.id == currentTodo.id);
    _memoryTodos.removeById(currentTodo.id);
    try {
      _chats.removeMessage(currentCard.sessionId, currentCard.id);
    } catch (_) {
      if (_todos.byId(currentTodo.id) == null) {
        _memoryTodos.insertAt(todoIndex, currentTodo);
      }
      rethrow;
    }
    return ChatTodoUndo._(
      currentCard,
      currentTodo,
      index,
      todoIndex,
      _undoOwner,
    );
  }

  ChatTodoRestoreResult restoreTodo(ChatTodoUndo undo) {
    if (!identical(undo._owner, _undoOwner) || undo._used) {
      return ChatTodoRestoreResult.unavailable;
    }
    // Consume before writes, including rejected attempts. The same receipt
    // must never revive a task deleted again after a restoration or conflict.
    undo._used = true;
    final card = undo.card;
    final todo = undo.todo;
    if (!mounted ||
        !_chats.mounted ||
        !_todos.mounted ||
        _chats.sessionById(card.sessionId) == null) {
      return ChatTodoRestoreResult.unavailable;
    }
    if (_todos.byId(todo.id) != null || _chats.messageById(card.id) != null) {
      return ChatTodoRestoreResult.conflict;
    }
    _memoryTodos.insertAt(undo._todoIndex, todo);
    try {
      // Store notifications are synchronous: also respect changes made by a
      // listener during the insertion instead of overwriting its newer state.
      if (!identical(_todos.byId(todo.id), todo) ||
          _chats.messageById(card.id) != null) {
        throw RepositoryException(
          RepositoryErrorCode.conflict,
          strings.relatedRecordsHaveChangedAndCannotBe,
        );
      }
      _chats.insertMessageAt(undo.messageIndex, card);
    } catch (_) {
      // Only compensate the record inserted by this attempt, never a later edit.
      if (identical(_todos.byId(todo.id), todo)) {
        _memoryTodos.removeById(todo.id);
      }
      rethrow;
    }
    return ChatTodoRestoreResult.restored;
  }

  @override
  void dispose() {
    _request++;
    _responseTimer?.cancel();
    _streamTimer?.cancel();
    super.dispose();
  }
}
