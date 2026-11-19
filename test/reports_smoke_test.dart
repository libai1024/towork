import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/workspace_scope_rail.dart';
import 'package:towork/features/reports/report_actions.dart';
import 'package:towork/features/reports/report_detail_page.dart';
import 'package:towork/features/reports/reports_page.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/theme/app_theme.dart';

Widget _app() {
  final router = GoRouter(
    initialLocation: '/reports',
    routes: [
      GoRoute(
        path: '/reports',
        builder: (_, _) => const ReportsPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                ReportDetailPage(reportId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
  addTearDown(router.dispose);
  return ProviderScope(
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

Finder _filterChip(String label) => find.descendant(
  of: find.byType(WorkspaceScopeRail),
  matching: find.text(label),
);

void main() {
  testWidgets('报告列表：月份分组 / 未读点 / 失败卡片 / 筛选', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // 分组头与卡片
    expect(find.textContaining('年'), findsWidgets);
    expect(find.text('稳步前进的一周'), findsOneWidget);
    expect(find.text('八月：输入与输出的平衡'), findsOneWidget);
    // 未读报告带 500 字重标题
    final unread = tester.widget<Text>(find.text('稳步前进的一周'));
    expect(unread.style?.fontWeight, FontWeight.w500);
    // 已读报告 400 字重
    final read = tester.widget<Text>(find.text('八月：输入与输出的平衡'));
    expect(read.style?.fontWeight, FontWeight.w400);
    // 失败卡片
    expect(find.textContaining('没写成'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    // 筛选：月报
    await tester.tap(_filterChip('月报'));
    await tester.pump();
    expect(find.text('八月：输入与输出的平衡'), findsOneWidget);
    expect(find.text('稳步前进的一周'), findsNothing);
    // 清除回全部
    await tester.tap(_filterChip('全部'));
    await tester.pump();
    expect(find.text('稳步前进的一周'), findsOneWidget);
  });

  testWidgets('进入详情即标已读，保留统计和洞察，移除重复落款', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ReportsPage)),
    );
    expect(
      container.read(reportListProvider.notifier).byId('r1')!.isRead,
      isFalse,
    );

    await tester.tap(find.text('稳步前进的一周'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 已读
    expect(
      container.read(reportListProvider.notifier).byId('r1')!.isRead,
      isTrue,
    );

    // 头部
    expect(find.text('稳步前进的一周'), findsWidgets);
    expect(find.textContaining('Kimi '), findsOneWidget);
    expect(find.text('AI'), findsWidgets);
    // 大数字卡片
    expect(find.text('完成率'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(find.text('逾期'), findsOneWidget);
    expect(find.text('新增数据'), findsOneWidget);
    // Markdown 正文
    expect(find.text('本周概览'), findsOneWidget);
    expect(find.text('核心数据变动'), findsOneWidget);
    expect(find.text('账户市值(元)'), findsOneWidget);
    // AI 洞察特殊排版
    expect(find.text('AI 洞察'), findsOneWidget);
    expect(find.textContaining('报告结束'), findsNothing);
  });

  testWidgets('手动生成：Sheet → 生成中进度态 → 4 秒后成稿插入列表', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('生成报告'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Sheet 标题与提交操作均可访问，不依赖具体字号。
    expect(find.text('生成报告'), findsWidgets);
    expect(find.text('周期'), findsOneWidget);
    expect(find.text('包含分类'), findsOneWidget);
    expect(find.text('保存为定时报告默认范围'), findsOneWidget);
    expect(find.textContaining('约消耗一次对话的额度'), findsNothing);

    // 分类多选：取消一个，生成仍可用
    await tester.tap(find.text('家庭'));
    await tester.pump();

    // 选「上周」快捷周期
    await tester.tap(find.text('上周'));
    await tester.pump();

    await tester.tap(find.widgetWithText(AppButton, '生成报告'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 进入详情进度态
    expect(find.text('生成中'), findsWidgets);
    expect(find.text('统计完成事项'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('汇总分类'), findsOneWidget);

    // mock 4 秒后成稿
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('本期概览'), findsOneWidget);
    expect(find.text('完成率'), findsOneWidget);
    expect(find.text('83'), findsOneWidget);
    expect(find.text('AI 洞察'), findsOneWidget);

    // 返回列表，新报告在顶部（详情内容已消失；列表页在 push 栈下保活，卡片仍可找到）
    await tester.tap(find.bySemanticsLabel('返回'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('本期概览'), findsNothing);
    expect(find.text('一步一步，都在往前'), findsWidgets);
  });

  testWidgets('删除软删除 + Toast 撤销恢复', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('收心的一周'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('report-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.longPress(find.text('收心的一周'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('删除'), findsWidgets);

    await tester.tap(find.widgetWithText(ReportMenuRow, '删除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('删除报告后保留原始数据。'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, '删除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 卡片消失 + 撤销 Toast
    expect(find.text('收心的一周'), findsNothing);
    expect(find.text('报告已删除'), findsOneWidget);

    await tester.tap(find.text('撤销'));
    await tester.pump();
    expect(find.text('收心的一周'), findsOneWidget);
  });
}
