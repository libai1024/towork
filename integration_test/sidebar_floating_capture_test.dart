import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/quota.dart';
import 'package:towork/domain/models/settings.dart';
import 'package:towork/domain/settings/model_accounts.dart';
import 'package:towork/domain/settings/model_settings.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';

/// Exercises the real sidebar with the in-memory demo workspace.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('sidebar controls stay fixed while history passes beneath them', (
    tester,
  ) async {
    final key = GlobalKey();
    final shots = <String, String>{};
    binding.reportData = {'screenshots': shots};
    final profile = ModelProfile(
      product: ProviderKind.zhipuCoding,
      model: 'glm-5.3-flash',
    );
    final sample = ModelAccount(
      id: 'sample-glm',
      profile: profile,
      credentialRef: 'fixture',
      quota: QuotaSnapshot(
        fetchedAt: DateTime.now(),
        windows: const [
          QuotaWindow(label: '5 小时', usedRatio: .2),
          QuotaWindow(label: '每周', usedRatio: .41),
          QuotaWindow(label: '每月', usedRatio: .15),
        ],
      ),
    );
    final state = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWithValue(
          const UserProfile(nickname: '小林', tier: '免费版'),
        ),
        liveModelAccountsProvider.overrideWithValue(
          ModelAccountsSnapshot(
            configuration: ModelConfiguration(profile: profile),
            accounts: [sample],
            activeId: sample.id,
          ),
        ),
      ],
    );
    final desktop = Platform.isMacOS || Platform.isLinux || Platform.isWindows;
    if (desktop) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1152, 820);
      await binding.setSurfaceSize(const Size(1152, 820));
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: UncontrolledProviderScope(
          container: state,
          child: const ToWorkApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (!desktop) {
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
    }
    final list = find.byKey(const ValueKey('sidebar-list'));
    ScrollPosition scroll() => tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)).first,
        )
        .position;
    final search = find.byKey(const ValueKey('sidebar-search'));
    final header = find.byKey(
      ValueKey(desktop ? 'sidebar-new-conversation' : 'sidebar-profile'),
    );
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      shots[name] = base64Encode(bytes.buffer.asUint8List());
      image.dispose();
    }

    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      state.read(themeModeProvider.notifier).state = theme;
      await tester.pumpAndSettle();
      scroll().jumpTo(0);
      await tester.pumpAndSettle();
      final top = tester.getRect(header);
      final bottom = tester.getRect(search);
      await shot('${theme.name}-top');
      expect(scroll().maxScrollExtent, greaterThan(0));
      if (!desktop &&
          theme == ThemeMode.light &&
          const bool.fromEnvironment('SIDEBAR_SCROLL_CLIP')) {
        final distance = scroll().maxScrollExtent * .86;
        for (var frame = 0; frame <= 32; frame++) {
          scroll().jumpTo(
            distance * Curves.easeInOutCubic.transform(frame / 32),
          );
          await shot('scroll-${frame.toString().padLeft(2, '0')}');
        }
      }
      scroll().jumpTo((scroll().maxScrollExtent * .66).roundToDouble());
      await shot('${theme.name}-scroll');
      expect(tester.getRect(header), top);
      expect(tester.getRect(search), bottom);
      scroll().jumpTo(scroll().maxScrollExtent);
      await tester.pumpAndSettle();
      final last = state.read(sessionListProvider).last.title;
      expect(tester.getBottomLeft(find.text(last)).dy, lessThan(bottom.top));
      expect(find.text(last).hitTestable(), findsOneWidget);
    }
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workspace-search-controls')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('关闭搜索'));
    await tester.pumpAndSettle();
    state.read(themeModeProvider.notifier).state = ThemeMode.light;
    state.read(appRouterProvider).go(AppRoutes.settings);
    await tester.pumpAndSettle();
    final settingsSearch = find.widgetWithText(TextField, '搜索设置');
    expect(settingsSearch.hitTestable(), findsOneWidget);
    expect(
      tester.getBottomLeft(settingsSearch).dy,
      greaterThan(tester.getSize(find.byType(ToWorkApp)).height * .8),
    );
    await shot('settings-search');
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
