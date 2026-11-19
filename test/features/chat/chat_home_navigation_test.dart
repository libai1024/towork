import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/core/widgets/glass_surface.dart';
import 'package:towork/features/chat/widgets/chat_header.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';

void main() {
  testWidgets('messages scroll behind the translucent header controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );
    container.read(currentSessionIdProvider.notifier).state = container
        .read(sessionListProvider)
        .first
        .id;
    await tester.pumpAndSettle();
    final list = tester.getRect(
      find.byKey(const ValueKey('chat-message-list')),
    );
    final header = tester.getRect(find.byType(ChatHeader));
    expect(list.top, header.top);
    final glass = tester.widget<GlassSurface>(
      find.byKey(const ValueKey('chat-header-glass')),
    );
    expect(glass.opacity, lessThan(.7));
    expect(glass.blur, 18);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'composer model, keyboard and workspace return preserve the draft',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            modelAccountsProvider.overrideWith((ref) {
              throw StateError(
                'Demo UI must not open the production account store',
              );
            }),
          ],
          child: const ToWorkApp(),
        ),
      );
      await tester.pumpAndSettle();
      final voice = find.byKey(const ValueKey('voice-input'));
      expect(
        find.descendant(
          of: voice,
          matching: find.byIcon(LucideIcons.audioLines),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: voice,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color == Colors.transparent,
          ),
        ),
        findsOneWidget,
      );
      for (final target in [
        find.byTooltip('打开菜单'),
        find.byTooltip('选择模型'),
        find.byKey(const ValueKey('add-attachment')),
        find.byKey(const ValueKey('switch-to-keyboard')),
        find.byKey(const ValueKey('voice-input')),
      ]) {
        final size = tester.getSize(target);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      final composer = tester.getRect(
        find.byKey(const ValueKey('chat-composer')),
      );
      final model = tester.getRect(find.byTooltip('选择模型'));
      expect(composer.contains(model.center), isTrue);
      expect(find.text('工作'), findsNothing);
      expect(find.text('资料'), findsNothing);
      expect(composer.bottom, closeTo(834, .01));
      await tester.tap(find.byKey(const ValueKey('switch-to-keyboard')));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('chat-text-input'));
      await tester.enterText(field, '回来后继续写这段草稿');
      await tester.pump();
      expect(tester.getSize(find.byTooltip('发送消息')).height, 48);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('待办'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ToWorkApp)),
      );
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, '回来后继续写这段草稿');
      expect(tester.takeException(), isNull);
    },
  );
}
