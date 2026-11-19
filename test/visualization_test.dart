import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/features/visualization/visualization_page.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  Widget buildPage() => ProviderScope(
    child: MaterialApp(theme: AppTheme.light, home: const VisualizationPage()),
  );

  Future<void> selectView(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel('切换日程视图'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('可视化页默认月历日程，统计视图通过菜单保留', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    expect(find.text('日程可视化'), findsOneWidget);
    expect(find.text('月'), findsOneWidget);
    expect(find.text('周'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('schedule-calendar-pane')),
      findsOneWidget,
    );
    expect(find.text('坚持强度'), findsNothing);
    await selectView(tester, '热力图');
    expect(find.text('坚持强度'), findsOneWidget);
    expect(find.textContaining('口径：'), findsOneWidget);
    expect(find.text('少'), findsOneWidget);
    expect(find.text('多'), findsOneWidget);
    expect(find.textContaining('全年'), findsOneWidget);
  });

  testWidgets('口径切换弹底部单选 Sheet', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    await selectView(tester, '热力图');
    await tester.tap(find.textContaining('口径：'));
    await tester.pumpAndSettle();
    expect(find.text('统计口径'), findsOneWidget);
    expect(find.text('完成 Todo 数'), findsOneWidget);
    expect(find.text('新增 Todo 数'), findsOneWidget);
    expect(find.text('新增数据条数'), findsOneWidget);

    // 切到新增数据条数：口径文案联动更新
    await tester.tap(find.text('新增数据条数'));
    await tester.pumpAndSettle();
    expect(find.text('口径：数据'), findsOneWidget);
    expect(find.textContaining('全年'), findsOneWidget);
  });

  testWidgets('四个视图切换：日历/分布/趋势各自渲染', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();

    // 日历
    await selectView(tester, '日历');
    expect(find.textContaining('年'), findsWidgets); // 「2026 年 9 月」卡头
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('一'), findsOneWidget); // 星期头

    // 分布
    await selectView(tester, '分布');
    expect(find.text('分类分布'), findsOneWidget);
    expect(find.text('完成率'), findsOneWidget);
    expect(find.textContaining('件 完成'), findsWidgets); // 图例行

    // 趋势
    await selectView(tester, '趋势');
    expect(find.text('创建 vs 完成'), findsOneWidget);
    expect(find.text('8 周'), findsOneWidget);
    expect(find.textContaining('近 8 周创建'), findsOneWidget);
    expect(find.textContaining('比上一周期'), findsOneWidget);
  });

  testWidgets('分类过滤在Sheet切换，图例单选继续同步', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('筛选分类'));
    await tester.pumpAndSettle();
    expect(find.text('全部'), findsOneWidget);
    await tester.tap(find.text('档案馆'));
    await tester.pump();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('schedule-calendar-pane')),
      findsOneWidget,
    );
    await selectView(tester, '分布');
    await tester.tap(find.textContaining('件 完成').first);
    await tester.pumpAndSettle();
    expect(find.text('分类分布'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('筛选分类'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(BottomSheet), matching: find.text('档案馆')),
      findsOneWidget,
    );
    await tester.tap(find.text('全部'));
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
