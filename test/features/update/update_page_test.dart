import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/update/update_provider.dart';
import 'package:towork/features/update/update_page.dart';
import 'package:towork/domain/update/app_update.dart';
import 'package:towork/theme/app_theme.dart';

import '../../support/update_fakes.dart';
import '../../support/code_update_fake.dart';

import 'package:towork/domain/update/code_update.dart';

void main() {
  late FakeUpdatePlatform platform;
  late FakeUpdateGateway gateway;
  late FakeCodeUpdateGateway code;
  setUp(() {
    platform = FakeUpdatePlatform();
    gateway = FakeUpdateGateway();
    code = FakeCodeUpdateGateway()..info = const CodeUpdateStatus();
  });
  Future<void> mount(WidgetTester tester, {bool large = false}) async {
    tester.view.physicalSize = Size(320, large ? 1000 : 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          codeUpdateGatewayProvider.overrideWithValue(code),
          updatePlatformProvider.overrideWithValue(platform),
          updateGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(large ? 2 : 1)),
            child: const UpdatePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'code patch offers compact update and restart without installation',
    (tester) async {
      gateway.release = null;
      code.info = const CodeUpdateStatus(supported: true, activeVersion: '2');
      await mount(tester);
      expect(find.text('1.1.1 (3) P2'), findsOneWidget);
      expect(find.text('更新并重启'), findsOneWidget);
      expect(find.text('下载更新'), findsNothing);
      await tester.ensureVisible(find.text('更新并重启'));
      await tester.tap(find.text('更新并重启'));
      await tester.pumpAndSettle();
      expect(code.restarts, 1);
      expect(find.text('立即重启'), findsOneWidget);
      expect(find.text('安装并重新打开'), findsNothing);
      expect(platform.installs, 0);
    },
  );

  testWidgets(
    'real buttons drive download, permission return and install cancel',
    (tester) async {
      await mount(tester);
      expect(find.text('1.1.1 (3)'), findsOneWidget);
      await tester.tap(find.text('下载更新'));
      await tester.pumpAndSettle();
      expect(find.text('安装包已就绪'), findsOneWidget);
      platform.allowed = false;
      await tester.tap(find.text('安装并重新打开'));
      await tester.pumpAndSettle();
      expect(find.text('需要安装应用权限'), findsOneWidget);
      platform.allowed = true;
      await tester.tap(find.text('安装并重新打开'));
      await tester.pumpAndSettle();
      platform.status = InstallStatus.cancelled;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('安装已取消，可以重试'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('progress, pause, and narrow large text remain usable', (
    tester,
  ) async {
    gateway.transfer = Completer<String>();
    await mount(tester, large: true);
    final download = find.text('下载更新');
    await tester.ensureVisible(download);
    await tester.tap(download);
    await tester.pump();
    await tester.pump();
    expect(find.text('0.5 / 1.0 MB'), findsOneWidget);
    final pause = find.text('暂停下载');
    await tester.ensureVisible(pause);
    await tester.tap(pause);
    await tester.pumpAndSettle();
    expect(find.text('下载已暂停，再次下载会继续传输'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delta size, applying status and full fallback stay explicit', (
    tester,
  ) async {
    gateway.release = updateFixtureRelease.selectPatch(
      AppPatch(
        fromVersionCode: 3,
        fromSha256: 'a' * 64,
        url: Uri.parse('https://example.test/a.hpatch'),
        sha256: 'b' * 64,
        size: 128 * 1024,
      ),
    );
    gateway.transfer = Completer<String>();
    await mount(tester);
    expect(find.textContaining('差量更新 0.1 MB'), findsOneWidget);
    await tester.tap(find.text('下载更新'));
    await tester.pump();
    await tester.pump();
    expect(find.text('0.1 / 0.1 MB'), findsOneWidget);
    gateway.applying!();
    await tester.pump();
    expect(find.text('正在合成安装包'), findsOneWidget);
    expect(find.text('取消更新'), findsOneWidget);
    gateway.fallback!();
    gateway.progress!(512 * 1024);
    await tester.pump();
    expect(find.textContaining('完整安装包 1.0 MB'), findsOneWidget);
    expect(find.text('差量更新未完成，已切换完整安装包。'), findsOneWidget);
    gateway.transfer!.complete('/private/updates/fixture.apk');
    await tester.pumpAndSettle();
    expect(find.text('安装并重新打开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
