import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/repositories/chat_repository.dart';
import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/repositories/chat_gateway.dart';
import 'package:towork/domain/repositories/repository_error.dart';
import 'package:towork/app/chat/chat_view_model.dart';

class _Gateway implements ChatGateway {
  final requests = <Completer<ChatReply>>[];
  @override
  Future<ChatReply> respond(String input) {
    final response = Completer<ChatReply>();
    requests.add(response);
    return response.future;
  }
}

class _RejectCards extends ChatRepository {
  _RejectCards() : super(initial: []);
  @override
  void appendMessage(ChatMessage message) {
    if (message.type == ChatMessageType.todoCard) {
      throw StateError('Simulated card persistence failure');
    }
    super.appendMessage(message);
  }
}

class _RejectRestoredCards extends ChatRepository {
  _RejectRestoredCards() : super(initial: []);
  @override
  void insertMessageAt(int index, ChatMessage message) {
    throw const RepositoryException(
      RepositoryErrorCode.conflict,
      'Simulated restoration failure',
    );
  }
}

class _Harness {
  _Harness({ChatRepository? repository})
    : chats = repository ?? ChatRepository(initial: []),
      todos = TodoRepository(initial: []) {
    controller = ChatViewModel(
      chats: chats,
      todos: todos,
      gateway: gateway,
      currentSession: () => sessionId,
      selectSession: (id) => sessionId = id,
    );
  }
  final ChatRepository chats;
  final TodoRepository todos;
  final gateway = _Gateway();
  late final ChatViewModel controller;
  String? sessionId;
  List<ChatMessage> get messages => chats.messagesOf(sessionId!);
  void dispose() {
    controller.dispose();
    chats.dispose();
    todos.dispose();
  }
}

(ChatMessage, Todo) _seedTaskCard(_Harness h) {
  final session = h.chats.createSession();
  h.sessionId = session.id;
  final todo = h.todos.addTodo(title: '任务');
  final card = ChatMessage(
    id: h.chats.nextMessageId(),
    sessionId: session.id,
    role: ChatRole.assistant,
    type: ChatMessageType.todoCard,
    content: '',
    createdAt: DateTime(2026),
    todoId: todo.id,
  );
  h.chats.appendMessage(card);
  return (card, todo);
}

void main() {
  test('cancel ignores an assistant response that arrives later', () {
    fakeAsync((async) {
      final h = _Harness();
      h.controller.send('创建待办', model: 'K3');
      h.controller.cancel();
      h.gateway.requests.single.complete(
        const ChatReply(
          text: '已完成',
          draft: TodoDraft(title: '不可迟到创建'),
        ),
      );
      async.elapse(const Duration(seconds: 10));
      expect(h.messages, hasLength(1));
      expect(h.todos.snapshot, isEmpty);
      expect(h.controller.snapshot.isGenerating, isFalse);
      h.dispose();
    });
  });

  test(
    'cancel before the first token removes the empty thinking placeholder',
    () {
      fakeAsync((async) {
        final h = _Harness();
        h.controller.send('hello', model: 'K3');
        h.gateway.requests.single.complete(const ChatReply(text: '回复'));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        expect(h.messages.last.content, isEmpty);
        h.controller.cancel();
        async.elapse(const Duration(seconds: 2));
        expect(h.messages, hasLength(1));
        h.dispose();
      });
    },
  );

  test(
    'cancel during streaming marks text stopped and never commits the task',
    () {
      fakeAsync((async) {
        final h = _Harness();
        h.controller.send('创建待办', model: 'K3');
        h.gateway.requests.single.complete(
          const ChatReply(
            text: '还有很多字需要输出',
            draft: TodoDraft(title: '任务'),
          ),
        );
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 1030));
        h.controller.cancel();
        final partial = h.messages.last.content;
        async.elapse(const Duration(seconds: 5));
        expect(h.messages.last.content, partial);
        expect(h.messages.last.stoppedByUser, isTrue);
        expect(h.todos.snapshot, isEmpty);
        h.dispose();
      });
    },
  );

  test('failed requests retry without duplicating the user message', () {
    fakeAsync((async) {
      final h = _Harness();
      h.controller.send('你好', model: '快速');
      h.gateway.requests.single.completeError(StateError('Offline'));
      async.flushMicrotasks();
      expect(h.controller.snapshot.error, isA<StateError>());
      expect(h.controller.retry(), isTrue);
      h.gateway.requests.last.complete(const ChatReply(text: '你好😀世界'));
      async.elapse(const Duration(seconds: 3));
      expect(h.messages.where((m) => m.role == ChatRole.user), hasLength(1));
      expect(h.messages.last.content, '你好😀世界');
      expect(h.messages.last.modelId, '快速');
      expect(h.controller.snapshot.error, isNull);
      h.dispose();
    });
  });

  test(
    'empty replies are failures and leave no infinite thinking indicator',
    () {
      fakeAsync((async) {
        final h = _Harness();
        h.controller.send('你好', model: 'K3');
        h.gateway.requests.single.complete(const ChatReply(text: ''));
        async.elapse(const Duration(seconds: 3));
        expect(h.messages, hasLength(1));
        expect(h.controller.snapshot.error, isNotNull);
        h.dispose();
      });
    },
  );

  test(
    'completion creates exactly one task, undo restores the original order',
    () {
      fakeAsync((async) {
        final h = _Harness();
        h.controller.send('创建待办', model: 'K3');
        expect(h.controller.send('重复发送', model: 'K3'), isFalse);
        h.gateway.requests.single.complete(
          const ChatReply(
            text: '已完成😀',
            draft: TodoDraft(title: '任务'),
          ),
        );
        async.elapse(const Duration(seconds: 3));
        expect(h.todos.snapshot, hasLength(1));
        final card = h.messages.last;
        h.chats.appendMessage(
          ChatMessage(
            id: 'later',
            sessionId: h.sessionId!,
            role: ChatRole.user,
            type: ChatMessageType.text,
            content: '后续消息',
            createdAt: DateTime(2026),
          ),
        );
        final undo = h.controller.undoTodo(card, h.todos.snapshot.single);
        expect(h.todos.snapshot, isEmpty);
        expect(h.controller.restoreTodo(undo), ChatTodoRestoreResult.restored);
        expect(
          h.controller.restoreTodo(undo),
          ChatTodoRestoreResult.unavailable,
        );
        expect(h.messages[h.messages.length - 2].id, card.id);
        expect(h.messages.last.id, 'later');
        expect(h.todos.snapshot, hasLength(1));
        h.dispose();
      });
    },
  );

  test('task creation rolls back if its conversation card cannot be saved', () {
    fakeAsync((async) {
      final h = _Harness(repository: _RejectCards());
      h.controller.send('创建待办', model: 'K3');
      h.gateway.requests.single.complete(
        const ChatReply(
          text: '回复',
          draft: TodoDraft(title: '不可孤立'),
        ),
      );
      async.elapse(const Duration(seconds: 3));
      expect(h.todos.snapshot, isEmpty);
      expect(h.controller.snapshot.error, isNotNull);
      h.dispose();
    });
  });

  test('disposal invalidates in-flight callbacks', () {
    fakeAsync((async) {
      final h = _Harness();
      h.controller.send('hello', model: 'K3');
      h.controller.dispose();
      h.gateway.requests.single.complete(const ChatReply(text: 'late'));
      async.elapse(const Duration(seconds: 3));
      expect(h.messages, hasLength(1));
      expect(h.todos.snapshot, isEmpty);
      h.chats.dispose();
      h.todos.dispose();
    });
  });

  group('task-card restoration', () {
    test('a consumed receipt cannot revive a task deleted again later', () {
      final h = _Harness();
      addTearDown(h.dispose);
      final (card, todo) = _seedTaskCard(h);
      final undo = h.controller.undoTodo(card, todo);
      expect(h.controller.restoreTodo(undo), ChatTodoRestoreResult.restored);

      h.todos.removeById(todo.id);
      h.chats.removeMessage(card.sessionId, card.id);
      expect(h.controller.restoreTodo(undo), ChatTodoRestoreResult.unavailable);
      expect(h.todos.byId(todo.id), isNull);
      expect(h.chats.messageById(card.id), isNull);
    });

    test('removal snapshots current records instead of stale UI models', () {
      final h = _Harness();
      addTearDown(h.dispose);
      final (oldCard, oldTodo) = _seedTaskCard(h);
      h.todos.updateTodo(oldTodo.copyWith(title: '最新待办'));
      h.chats.updateMessage(oldCard.copyWith(content: '最新任务卡'));
      final currentTodo = h.todos.byId(oldTodo.id)!;
      final currentCard = h.chats.messageById(oldCard.id)!;

      final undo = h.controller.undoTodo(oldCard, oldTodo);
      expect(h.controller.restoreTodo(undo), ChatTodoRestoreResult.restored);
      expect(h.todos.byId(oldTodo.id), same(currentTodo));
      expect(h.chats.messageById(oldCard.id), same(currentCard));
    });

    test('a replacement task with the same ID is preserved on conflict', () {
      final h = _Harness();
      addTearDown(h.dispose);
      final (card, todo) = _seedTaskCard(h);
      final undo = h.controller.undoTodo(card, todo);
      final replacement = h.todos.addTodo(id: todo.id, title: '后来的同 ID 待办');

      expect(h.controller.restoreTodo(undo), ChatTodoRestoreResult.conflict);
      expect(h.todos.byId(todo.id), same(replacement));
      expect(h.chats.messageById(card.id), isNull);
      h.todos.removeById(todo.id);
      expect(h.controller.restoreTodo(undo), ChatTodoRestoreResult.unavailable);
      expect(h.todos.byId(todo.id), isNull);
    });

    test(
      'a replacement message with the same ID never resurrects the task',
      () {
        final h = _Harness();
        addTearDown(h.dispose);
        final (card, todo) = _seedTaskCard(h);
        final undo = h.controller.undoTodo(card, todo);
        final replacement = card.copyWith(content: '后来创建的消息');
        h.chats.appendMessage(replacement);

        expect(h.controller.restoreTodo(undo), ChatTodoRestoreResult.conflict);
        expect(h.chats.messageById(card.id), same(replacement));
        expect(h.todos.byId(todo.id), isNull);
      },
    );

    test('a failed card write compensates only this inserted task', () {
      final h = _Harness(repository: _RejectRestoredCards());
      addTearDown(h.dispose);
      final (card, todo) = _seedTaskCard(h);
      final undo = h.controller.undoTodo(card, todo);
      final unrelated = h.todos.addTodo(title: '之后创建的待办');

      expect(
        () => h.controller.restoreTodo(undo),
        throwsA(isA<RepositoryException>()),
      );
      expect(h.todos.snapshot, [unrelated]);
      expect(h.todos.byId(todo.id), isNull);
      expect(h.chats.messageById(card.id), isNull);
      expect(h.controller.restoreTodo(undo), ChatTodoRestoreResult.unavailable);
    });

    test(
      'a listener edit during restoration is not overwritten by compensation',
      () {
        final h = _Harness();
        addTearDown(h.dispose);
        final (card, todo) = _seedTaskCard(h);
        final undo = h.controller.undoTodo(card, todo);
        var edited = false;
        final removeListener = h.todos.addListener((_) {
          if (!edited && h.todos.byId(todo.id) != null) {
            edited = true;
            h.todos.updateTodo(todo.copyWith(title: '插入后发生的编辑'));
          }
        }, fireImmediately: false);
        try {
          expect(
            () => h.controller.restoreTodo(undo),
            throwsA(isA<RepositoryException>()),
          );
          expect(h.todos.byId(todo.id)!.title, '插入后发生的编辑');
          expect(h.chats.messageById(card.id), isNull);
        } finally {
          removeListener();
        }
      },
    );

    test('a changed card association cannot remove an unrelated task', () {
      final h = _Harness();
      addTearDown(h.dispose);
      final (card, todo) = _seedTaskCard(h);
      final other = h.todos.addTodo(title: '另一任务');
      h.chats.updateMessage(card.copyWith(todoId: other.id));

      expect(
        () => h.controller.undoTodo(card, todo),
        throwsA(isA<RepositoryException>()),
      );
      expect(h.todos.byId(todo.id), same(todo));
      expect(h.todos.byId(other.id), same(other));
      expect(h.chats.messageById(card.id)!.todoId, other.id);
    });
  });
}
