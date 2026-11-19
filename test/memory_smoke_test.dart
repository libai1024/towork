import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/memory_type_providers.dart';
import 'package:towork/features/memory/memory_page.dart';
import 'package:towork/features/memory/widgets/memory_list_row.dart';
import 'package:towork/theme/app_theme.dart';

Widget _app({ProviderContainer? container, ThemeData? theme}) {
  final app = MaterialApp(
    theme: theme ?? AppTheme.light,
    home: const MemoryPage(),
  );
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
}

Future<void> _load(
  WidgetTester tester, {
  ProviderContainer? container,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(_app(container: container, theme: theme));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('记忆库更多菜单列出自主写入的场景', (tester) async {
    await _load(tester);
    await tester.tap(find.bySemanticsLabel('更多操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('记忆规则'));
    await tester.pumpAndSettle();
    for (final item in ['长期偏好', '固定流程', '稳定职责', '项目约定', '术语别名', '事实纠正']) {
      expect(find.text(item), findsOneWidget);
    }
  });

  testWidgets(
    'compact memory list keeps source, confidence and expiry in detail',
    (tester) async {
      await _load(tester);
      expect(find.text('记忆库'), findsOneWidget);
      expect(find.text('事实 3'), findsOneWidget);
      expect(find.byType(MemoryListRow), findsWidgets);
      expect(find.text('置信度'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mem1')));
      await tester.pumpAndSettle();
      expect(find.text('记忆详情'), findsOneWidget);
      expect(find.text('AI 提取'), findsOneWidget);
      expect(find.text('高 93%'), findsOneWidget);
      expect(find.text('长期有效'), findsOneWidget);
      expect(find.text('来自会话「档案接收登记流程」'), findsOneWidget);
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('复制'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    },
  );

  testWidgets('type index and bottom search narrow the same list', (
    tester,
  ) async {
    await _load(tester);
    await tester.tap(find.text('偏好'));
    await tester.pumpAndSettle();
    expect(find.text('偏好 3'), findsOneWidget);
    expect(find.text('事实 3'), findsNothing);
    await tester.tap(find.text('全部'));
    await tester.enterText(find.byType(TextField), '茅台');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('事件 1'), findsOneWidget);
    expect(find.byType(MemoryListRow), findsOneWidget);
  });

  testWidgets('custom type can receive an entry and survives page remount', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _load(tester, container: container);
    await tester.tap(find.byTooltip('新增类型'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('memory-type-name')),
      '投资原则',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();
    expect(container.read(memoryTypesProvider).last.label, '投资原则');
    await tester.tap(find.bySemanticsLabel('新增记忆').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '控制单一公司的仓位');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('投资原则 1'), findsOneWidget);
    expect(
      container.read(memoryListProvider).first.customTypeId,
      container.read(memoryTypesProvider).last.id,
    );
    await tester.pumpWidget(const SizedBox());
    await _load(tester, container: container);
    await tester.tap(find.text('投资原则'));
    await tester.pumpAndSettle();
    expect(find.text('投资原则 1'), findsOneWidget);
    expect(find.byType(MemoryListRow), findsOneWidget);
  });

  testWidgets('paused memory retains management and prevents new entries', (
    tester,
  ) async {
    await _load(tester);
    await tester.tap(find.bySemanticsLabel('免记忆模式，当前关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开启'));
    await tester.pumpAndSettle();
    expect(find.text('免记忆模式已开启，新对话不会写入记忆库'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('新增记忆'));
    await tester.pumpAndSettle();
    expect(find.text('免记忆模式下不可新增'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('已恢复记忆'), findsOneWidget);
  });

  testWidgets('delete confirmation and undo preserve entry type', (
    tester,
  ) async {
    await _load(tester);
    await tester.tap(find.text('偏好'));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('mem4'));
    await tester.longPress(card);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条记忆？'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    expect(find.text('偏好 3'), findsOneWidget);
  });

  testWidgets('clear all remains an explicit hold-to-confirm operation', (
    tester,
  ) async {
    await _load(tester);
    await tester.tap(find.bySemanticsLabel('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清空全部记忆'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('长按 1 秒清空'));
    await tester.pumpAndSettle();
    expect(find.text('清空全部记忆？'), findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('长按 1 秒清空')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 1100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('记忆库已清空'), findsOneWidget);
    expect(find.text('还没有记忆'), findsOneWidget);
  });

  for (final width in [375.0, 1280.0]) {
    testWidgets('memory layout has no overflow at width $width in dark mode', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _load(tester, theme: AppTheme.dark);
      expect(find.byTooltip('新增类型'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('事件'));
      await tester.pumpAndSettle();
      expect(find.text('事件 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
