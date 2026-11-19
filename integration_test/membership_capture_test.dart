import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:towork/app/membership_plan.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/domain/models/settings.dart';
import 'package:towork/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native membership sheet packages badges and celebration', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    final screenshots = <String, String>{};
    binding.reportData = {'screenshots': screenshots};
    final state = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWithValue(
          const UserProfile(nickname: '小林', tier: '免费版'),
        ),
      ],
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: UncontrolledProviderScope(
          container: state,
          child: const ToWorkApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> shot(String name) async {
      expect(tester.takeException(), isNull, reason: name);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      screenshots[name] = base64Encode(bytes.buffer.asUint8List());
      image.dispose();
    }

    Finder tab(int tier) => find.byWidgetPredicate(
      (w) =>
          w is AppPressable &&
          w.semanticLabel == '选择 ${MembershipFamily.music.englishName(tier)}',
    );
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    await shot('sidebar-note');
    await tester.tap(find.text('Note'));
    await tester.pumpAndSettle();
    await shot('prelude');
    for (final tier in [2, 3, 0, 1]) {
      await tester.tap(tab(tier));
      if (tier == 2) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await shot('switching');
      }
      await tester.pumpAndSettle();
      await shot(MembershipFamily.music.englishName(tier).toLowerCase());
    }
    await tester.tap(find.text('切换为 Prelude'));
    await tester.pumpAndSettle();
    await shot('prelude-success');
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    expect(state.read(membershipSelectionProvider)?.tier, 1);
    await tester.tap(find.byTooltip('打开菜单'));
    await tester.pumpAndSettle();
    await shot('sidebar-prelude');
    state.read(themeModeProvider.notifier).state = ThemeMode.dark;
    await tester.pumpAndSettle();
    await shot('sidebar-dark');
    await tester.tap(find.text('Prelude'));
    await tester.pumpAndSettle();
    await shot('dark-prelude');
    await tester.tap(tab(3));
    await tester.pumpAndSettle();
    await shot('dark-symphony');
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
