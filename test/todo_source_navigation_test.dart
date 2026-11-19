import 'package:towork/data/repositories/todo_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/todo/todo_list_page.dart';
import 'package:towork/core/todo/todo_detail_sheet.dart';
import 'package:towork/main.dart';

void main() {
  testWidgets(
    'task source opens its original session from list and detail, missing source stays put',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final todos = TodoRepository(initial: []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [todoListProvider.overrideWith((ref) => todos)],
          child: const ToWorkApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ToWorkApp)),
      );
      final router = container.read(appRouterProvider);
      final chats = container.read(sessionListProvider.notifier);
      final sourceSession = chats.createSession();
      final unrelatedSession = chats.createSession();
      final message = ChatMessage(
        id: chats.nextMessageId(),
        sessionId: sourceSession.id,
        role: ChatRole.user,
        type: ChatMessageType.text,
        content: '来源回归：帮我整理项目材料',
        createdAt: DateTime.now(),
      );
      chats.appendMessage(message);
      final todo = todos.addTodo(
        title: '验证原始会话导航',
        source: TodoSource.ai,
        sourceMessageId: message.id,
      );
      container.read(currentSessionIdProvider.notifier).state =
          unrelatedSession.id;
      router.go(AppRoutes.todos);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Tooltip && (w.message as String).contains('查看来源会话'),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
      expect(container.read(currentSessionIdProvider), sourceSession.id);
      expect(find.text(message.content), findsOneWidget);

      container.read(currentSessionIdProvider.notifier).state =
          unrelatedSession.id;
      router.go(AppRoutes.todos);
      await tester.pumpAndSettle();
      await tester.tap(find.text(todo.title));
      await tester.pumpAndSettle();
      expect(find.byType(TodoDetailSheet), findsOneWidget);
      final sourceCard = find.byWidgetPredicate(
        (widget) =>
            widget is AppPressable &&
            (widget.semanticLabel?.startsWith('由对话生成，原文：') ?? false),
      );
      await tester.scrollUntilVisible(
        sourceCard,
        200,
        scrollable: find
            .descendant(
              of: find.byType(TodoDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(sourceCard);
      await tester.pumpAndSettle();
      expect(find.byType(TodoDetailSheet), findsNothing);
      expect(container.read(currentSessionIdProvider), sourceSession.id);
      expect(find.text(message.content), findsOneWidget);

      chats.removeMessage(sourceSession.id, message.id);
      container.read(currentSessionIdProvider.notifier).state =
          unrelatedSession.id;
      router.go(AppRoutes.todos);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is Tooltip && (w.message as String).contains('查看来源会话'),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.todos);
      expect(find.byType(TodoListPage), findsOneWidget);
      expect(container.read(currentSessionIdProvider), unrelatedSession.id);
      expect(find.text('原始对话已不可用'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
