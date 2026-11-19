import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/exports.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/workspace_scope_rail.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/reports/reports_page.dart';
import 'package:towork/features/settings/settings_page.dart';
import 'package:towork/theme/app_theme.dart';

Widget _app(Widget page, {bool dark = false}) => ProviderScope(
  child: MaterialApp(theme: dark ? AppTheme.dark : AppTheme.light, home: page),
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Finder _scope(String label) => find.descendant(
  of: find.byType(WorkspaceScopeRail),
  matching: find.text(label),
);

void main() {
  testWidgets('report search combines with the narrow type scope and clears', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(const ReportsPage()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '八月');
    await tester.pump();
    expect(find.text('八月：输入与输出的平衡'), findsOneWidget);
    expect(find.text('稳步前进的一周'), findsNothing);

    await tester.tap(_scope('周报'));
    await tester.pump();
    expect(find.text('没有找到相关报告'), findsOneWidget);
    await tester.tap(_scope('月报'));
    await tester.pump();
    expect(find.text('八月：输入与输出的平衡'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('清除搜索'));
    await tester.tap(_scope('全部'));
    await tester.pump();
    expect(find.text('稳步前进的一周'), findsOneWidget);
    expect(find.bySemanticsLabel('生成报告'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact report retry keeps confirmation and updates the record',
    (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(const ReportsPage(), dark: true));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ReportsPage)),
      );
      expect(
        container.read(reportListProvider.notifier).byId('r3')!.status,
        ReportStatus.failed,
      );
      await tester.ensureVisible(find.text('重试'));
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('重新生成？'), findsOneWidget);
      expect(find.widgetWithText(AppButton, '取消'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, '重新生成'));
      await tester.pump();
      expect(
        container.read(reportListProvider.notifier).byId('r3')!.status,
        ReportStatus.generating,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(
        container.read(reportListProvider.notifier).byId('r3')!.status,
        ReportStatus.ready,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('flat settings search preserves controls and real export', (
    tester,
  ) async {
    _phone(tester);
    // widget 测试运行在 FakeAsync 下,真实异步 IO 会永久挂起,统一用同步 API。
    final exports = Directory.systemTemp.createTempSync('towork_exports');
    addTearDown(() => exports.deleteSync(recursive: true));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportsDirectoryProvider.overrideWith((ref) async => exports),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPage)),
    );
    await tester.enterText(find.byType(TextField), '免记忆');
    await tester.pump();
    expect(find.text('免记忆模式'), findsOneWidget);
    expect(find.text('AI 写入权限'), findsNothing);
    expect(find.text('账号'), findsNothing);
    await tester.tap(find.text('免记忆模式'));
    await tester.pump();
    expect(container.read(memoryPausedProvider), isTrue);

    await tester.enterText(find.byType(TextField), '数据备份');
    await tester.pump();
    expect(find.text('一键导出'), findsOneWidget);
    expect(find.text('上次导出'), findsOneWidget);
    expect(find.text('尚未导出'), findsOneWidget);
    await tester.tap(find.text('一键导出'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('已导出 towork_backup_'), findsOneWidget);
    expect(exports.listSync().whereType<File>(), isNotEmpty);

    await tester.enterText(find.byType(TextField), '不存在的设置');
    await tester.pump();
    expect(find.text('没有找到相关设置'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('清除搜索'));
    await tester.pump();
    expect(find.text('账号'), findsOneWidget);
    expect(find.text('AI 写入权限'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
