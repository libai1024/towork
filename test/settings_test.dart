import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/features/settings/settings_page.dart';
import 'package:towork/features/settings/widgets/settings_shared.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/main.dart';
import 'package:towork/app/update/update_provider.dart';

import 'support/update_fakes.dart';

Widget _wrap(Widget home) => ProviderScope(
  overrides: [
    initialAppLocationProvider.overrideWithValue(AppRoutes.settings),
    appVersionProvider.overrideWithValue('1.1.2 (4)'),
  ],
  child: const ToWorkApp(),
);

void main() {
  // 拉高视口，让设置首页/额度页所有分组进入 ListView 构建区。
  void tallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('设置首页：分组与关键行渲染', (tester) async {
    tallSurface(tester);
    await tester.pumpWidget(_wrap(const SettingsPage()));
    await tester.pump();

    for (final g in ['账号', 'AI', '通知', '外观', '数据备份', '关于']) {
      expect(find.text(g), findsOneWidget, reason: g);
    }
    expect(find.text('登月者0830'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('模型与额度'), findsOneWidget);
    expect(find.text('添加 Key'), findsOneWidget); // 演示态没有模型账户
    expect(find.text('AI 写入权限'), findsOneWidget);
    expect(find.text('智能确认'), findsOneWidget);
    expect(find.text('免记忆模式'), findsOneWidget);
    expect(find.text('每日晨报'), findsOneWidget);
    expect(find.text('08:30'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('一键导出'), findsOneWidget);
    expect(find.text('尚未导出'), findsOneWidget);
    expect(find.text('1.1.2 (4)'), findsOneWidget);
    expect(find.text('开源许可'), findsOneWidget);
  });

  testWidgets('Android 从设置进入真实更新页面', (tester) async {
    tallSurface(tester);
    final platform = FakeUpdatePlatform();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialAppLocationProvider.overrideWithValue(AppRoutes.settings),
          updatePlatformProvider.overrideWithValue(platform),
          updateGatewayProvider.overrideWithValue(FakeUpdateGateway()),
        ],
        child: const ToWorkApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1.1.1 (3)'), findsOneWidget);
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('下载更新'), findsOneWidget);
  });

  testWidgets('设置首页：AI 写入权限 Sheet 三档，自动执行有警示', (tester) async {
    tallSurface(tester);
    await tester.pumpWidget(_wrap(const SettingsPage()));
    await tester.pump();

    await tester.tap(find.text('AI 写入权限'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('总是询问'), findsOneWidget);
    expect(find.text('自动执行'), findsOneWidget);
    expect(find.text('待办自动执行并保留修改记录；表格写入仍需确认'), findsOneWidget);

    await tester.tap(find.text('自动执行'));
    await tester.pump();
    await tester.pumpAndSettle();
    // 选中后行内右值更新 + Toast
    expect(find.text('AI 写入权限已设为「自动执行」'), findsOneWidget);
    final el = tester.element(find.byType(SettingsPage));
    expect(
      ProviderScope.containerOf(el).read(aiWritePermissionProvider),
      AiWritePermission.auto,
    );
  });

  testWidgets('设置首页：默认输入方式 Sheet 复用选项行语法，选中即生效', (tester) async {
    tallSurface(tester);
    await tester.pumpWidget(_wrap(const SettingsPage()));
    await tester.pump();

    await tester.tap(find.text('默认输入方式'));
    await tester.pump();
    await tester.pumpAndSettle();
    // 行右值「语音」+ Sheet 内两个选项；键盘选项此刻唯一可点。
    expect(find.text('语音'), findsNWidgets(2));
    expect(find.text('键盘'), findsOneWidget);

    await tester.tap(find.text('键盘'));
    await tester.pump();
    await tester.pumpAndSettle();
    final el = tester.element(find.byType(SettingsPage));
    expect(
      ProviderScope.containerOf(el).read(defaultInputModeProvider),
      ChatInputMode.keyboard,
    );
    // Sheet 关闭后行右值同步为「键盘」。
    expect(find.text('键盘'), findsOneWidget);
    expect(find.text('语音'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('外观页：紧凑行切换主题及字号', (tester) async {
    tallSurface(tester);
    await tester.pumpWidget(_wrap(const SettingsPage()));
    await tester.pump();

    await tester.tap(find.text('主题'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('浅色'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);
    expect(find.text('小'), findsOneWidget);
    expect(find.text('大'), findsOneWidget);

    await tester.tap(find.text('深色'));
    await tester.pump();
    await tester.pumpAndSettle();
    final el = tester.element(find.text('深色'));
    expect(
      ProviderScope.containerOf(el).read(themeModeProvider),
      ThemeMode.dark,
    );

    final standardRow = find.ancestor(
      of: find.text('标准'),
      matching: find.byType(SheetOptionRow),
    );
    expect(tester.getSize(standardRow).height, 44);
    await tester.tap(find.text('小'));
    await tester.pumpAndSettle();
    expect(ProviderScope.containerOf(el).read(fontScaleProvider), 0.9);

    // 长按彩蛋：真实月相 Toast
    await tester.longPress(find.text('跟随系统'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('今晚是'), findsOneWidget);
  });
}
