import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/main.dart';

/// Native-engine verification of the selected subpage designs. Run with the
/// existing test_driver/capture.dart to export light/dark screenshots.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  final shots = <String, String>{};
  final platform = Platform.isAndroid ? 'android' : 'desktop';

  testWidgets('selected subpages render on native platforms', (tester) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!Platform.isAndroid) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      await binding.setSurfaceSize(const Size(1280, 900));
    }
    binding.reportData = {'screenshots': shots};
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: const ProviderScope(child: ToWorkApp()),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ToWorkApp)),
    );
    final router = container.read(appRouterProvider);
    final routes = <(String, String, String)>[
      ('category', AppRoutes.todosForCategory('cat_stock'), '分类：炒股'),
      ('data', AppRoutes.dataTables, '核心数据'),
      ('schedule', AppRoutes.visualization, '日程可视化'),
      ('reports', AppRoutes.reports, '报告'),
      ('memory', AppRoutes.memory, '记忆库'),
      ('settings', AppRoutes.settings, '设置'),
    ];
    const onlyPage = String.fromEnvironment('WALKTHROUGH_PAGE');
    for (final theme in [ThemeMode.light, ThemeMode.dark]) {
      container.read(themeModeProvider.notifier).state = theme;
      for (final (name, path, title) in routes) {
        if (onlyPage.isNotEmpty && onlyPage != name) continue;
        router.go(path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        expect(find.text(title), findsWidgets);
        expect(
          tester.takeException(),
          isNull,
          reason: '$platform $name ${theme.name}',
        );
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        shots['$platform-subpages-$name-${theme.name}'] = base64Encode(
          bytes!.buffer.asUint8List(),
        );
        image.dispose();
      }
    }
  });
}
