import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/tier_badge.dart';
import 'package:towork/main.dart';
import 'package:towork/features/chat/widgets/chat_drawer.dart';
import 'package:towork/theme/app_colors.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  testWidgets('对话首页空态显示问候语与输入框', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
    await tester.pump();

    // 问候语包含昵称
    expect(find.textContaining('登月者0830'), findsOneWidget);
    // 建议 chip
    expect(find.text('提醒我明天交报告'), findsNothing);
    expect(find.byKey(const ValueKey('voice-input')), findsOneWidget);
    // 模型选择器
    expect(find.byTooltip('选择模型'), findsOneWidget);
  });

  testWidgets('抽屉侧栏包含五段结构与种子数据', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
    await tester.pump();

    // 点头像打开抽屉
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();

    // 用户区 TierBadge
    expect(find.text('Note'), findsOneWidget);
    // 功能入口两行三列
    for (final label in ['待办', '日程', '报告', '数据', '记忆', '设置']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // 分类区
    expect(find.text('分类'), findsOneWidget);

    expect(find.text('炒股'), findsOneWidget);
    // 历史会话区在视口下方，滚动后可见（种子数据）
    final drawerScrollable = find
        .descendant(
          of: find.byType(ChatDrawer),
          matching: find.byType(Scrollable),
        )
        .first;
    for (final label in ['新建分类', '历史会话', '明天的工作台']) {
      await tester.scrollUntilVisible(
        find.text(label),
        60,
        scrollable: drawerScrollable,
      );
      expect(find.text(label), findsOneWidget);
    }
    // 底部搜索
    expect(find.text('搜索'), findsOneWidget);
  });

  testWidgets('发送含「提醒/明天/交」的消息生成 AI Todo 卡片并可撤销恢复', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );
    final initialTodos = container.read(todoListProvider);

    if (find
        .byKey(const ValueKey('switch-to-keyboard'))
        .evaluate()
        .isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('switch-to-keyboard')));
      await tester.pumpAndSettle();
    }
    await tester.enterText(
      find.byType(EditableText).first,
      '提醒我明天下午三点前把报告发给王总',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    // 1s mock 延迟 + 流式输出
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('已为你建好这条待办：'), findsOneWidget);
    expect(find.text('已创建'), findsOneWidget);
    expect(find.text('AI'), findsNothing);
    expect(find.textContaining('把报告发给王总'), findsWidgets);
    expect(find.byTooltip('修改待办'), findsOneWidget);
    expect(find.byTooltip('撤销待办'), findsOneWidget);
    expect(find.byTooltip('复制回复'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('已为你建好这条待办：')).dx,
      tester.getTopLeft(find.byKey(const ValueKey('created-todo-content'))).dx,
    );
    final replyBottom = tester.getBottomLeft(find.text('已为你建好这条待办：')).dy;
    final cardTop = tester
        .getTopLeft(find.byKey(const ValueKey('created-todo-content')))
        .dy;
    expect(cardTop - replyBottom, lessThanOrEqualTo(8));
    expect(
      tester.getTopLeft(find.byTooltip('复制回复')).dy,
      greaterThanOrEqualTo(
        tester
            .getBottomLeft(find.byKey(const ValueKey('created-todo-content')))
            .dy,
      ),
    );
    final created = container
        .read(todoListProvider)
        .singleWhere((todo) => initialTodos.every((old) => old.id != todo.id));
    expect(created.title, contains('把报告发给王总'));

    // 撤销 → Toast 可恢复
    await tester.tap(find.byTooltip('撤销待办'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(todoListProvider.notifier).byId(created.id), isNull);
    expect(container.read(todoListProvider).length, initialTodos.length);
    expect(find.text('已撤销这条待办'), findsOneWidget);
    expect(find.text('恢复'), findsOneWidget);
    await tester.tap(find.text('恢复'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('修改待办'), findsOneWidget);
    expect(
      container.read(todoListProvider.notifier).byId(created.id)?.title,
      created.title,
    );
    expect(container.read(todoListProvider).length, initialTodos.length + 1);
  });

  testWidgets('暗色主题（月之暗面）token 与 TierBadge 反色', (tester) async {
    final dark = AppTheme.dark;
    expect(dark.scaffoldBackgroundColor, AppColors.dark.bgGround);
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.primary, AppColors.dark.brand);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: TierBadge(tier: 'Allegretto')),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(TierBadge),
        matching: find.byType(Container),
      ),
    );
    // 暗面使用统一的中性反色 token，文字与背景成对更新。
    expect(
      (container.decoration! as BoxDecoration).color,
      AppColors.dark.brand,
    );
    final label = tester.widget<Text>(find.text('Allegretto'));
    expect(label.style!.color, AppColors.dark.onBrand);
  });
}
