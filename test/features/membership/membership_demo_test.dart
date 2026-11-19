import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/membership_plan.dart';
import 'package:towork/app/apple_distribution.dart';
import 'package:towork/core/membership/membership_badge.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/tier_badge.dart';
import 'package:towork/features/membership/membership_details.dart';
import 'package:towork/features/membership/membership_page.dart';
import 'package:towork/features/membership/membership_success.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/theme/app_theme.dart';

Future<ProviderContainer> mount(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  bool reduce = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduce);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(const ProviderScope(child: ToWorkApp()));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(ToWorkApp)));
}

Finder tab(String label) => find.byWidgetPredicate(
  (widget) => widget is AppPressable && widget.semanticLabel == '选择 $label',
);

void main() {
  for (final beta in [false, true]) {
    testWidgets('iOS membership is fixed by distribution ($beta)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [testFlightProvider.overrideWith((ref) async => beta)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: MembershipBadge(
                tier: 'Max',
                onTap: () => fail('opened paid plans'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final badge = tester.widget<TierBadge>(find.byType(TierBadge));
      expect(badge.tier, beta ? 'Prelude' : 'Note');
      expect(badge.onTap, isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets(
    'sidebar opens compact packages directly; dismiss discards browsing',
    (tester) async {
      final state = await mount(tester);
      final original = state.read(userProfileProvider);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      expect(find.text('Note'), findsOneWidget);
      final badge = tester.widget<TierBadge>(find.byType(TierBadge));
      expect(badge.background, isNotNull);
      expect(badge.leading, isNotNull);
      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();
      final sheet = find.byKey(const ValueKey('membership-sheet'));
      expect(tester.getTopLeft(sheet).dy, greaterThan(250));
      expect(tester.getBottomRight(sheet).dy, 844);
      expect(find.byType(MembershipPage), findsOneWidget);
      expect(find.text('500 点'), findsOneWidget);
      expect(find.text('短上下文'), findsOneWidget);
      expect(find.textContaining(RegExp('演示|模拟|示例|重置|重播')), findsNothing);
      final size = tester.getSize(sheet);
      for (final title in ['Note', 'Prelude', 'Sonata', 'Symphony']) {
        await tester.tap(tab(title));
        await tester.pumpAndSettle();
        expect(tester.getSize(sheet), size);
        final button = find.byKey(const ValueKey('membership-apply'));
        final detail = find.byType(MembershipDetails);
        expect(
          tester.getTopLeft(button).dy - tester.getBottomLeft(detail).dy,
          inInclusiveRange(0, 10),
        );
      }
      // An interrupted switch keeps all choices and lands on the final choice.
      await tester.tap(tab('Note'));
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(tab('Prelude'));
      await tester.pumpAndSettle();
      expect(find.text('500 点'), findsOneWidget);
      await tester.tap(find.byTooltip('关闭会员'));
      await tester.pumpAndSettle();
      expect(find.byType(MembershipPage), findsNothing);
      expect(state.read(membershipSelectionProvider), isNull);
      expect(state.read(userProfileProvider), same(original));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Prelude and annual packages update badge and preserve real account',
    (tester) async {
      final state = await mount(tester);
      final original = state.read(userProfileProvider);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      final noteColor = tester
          .widget<TierBadge>(find.byType(TierBadge))
          .background;
      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('切换为 Prelude'));
      await tester.pumpAndSettle();
      expect(find.byType(MembershipSuccess), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('membership-success'))),
        const Size(390, 844),
      );
      expect(
        find.byKey(const ValueKey('membership-brand-logo')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('membership-tier-logo')),
        findsOneWidget,
      );
      expect(find.text('方案已切换'), findsOneWidget);
      expect(find.text('每月 500 积分'), findsOneWidget);
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byType(MembershipPage), findsNothing);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      final preludeBadge = tester.widget<TierBadge>(find.byType(TierBadge));
      expect(preludeBadge.tier, 'Prelude');
      expect(preludeBadge.background, isNot(noteColor));
      await tester.tap(find.text('Prelude'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppButton>(find.byKey(const ValueKey('membership-apply')))
            .enabled,
        isFalse,
      );
      await tester.tap(tab('Sonata'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('年付  ¥380'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('切换为 Sonata'));
      await tester.pumpAndSettle();
      expect(state.read(membershipSelectionProvider)?.annual, isTrue);
      expect(state.read(membershipSelectionProvider)?.tier, 2);
      expect(state.read(userProfileProvider), same(original));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small screen large text and reduced motion keep packages usable',
    (tester) async {
      final state = await mount(tester, width: 320, height: 640, reduce: true);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.tap(find.byTooltip('打开菜单'));
      await tester.pumpAndSettle();
      state.read(membershipSelectionProvider.notifier).state =
          const MembershipPlan(family: MembershipFamily.music, tier: 2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      state.read(appRouterProvider).go(AppRoutes.membership);
      await tester.pumpAndSettle();
      for (final family in [MembershipFamily.music]) {
        for (var i = 0; i < 4; i++) {
          await tester.ensureVisible(tab(family.englishName(i)));
          await tester.tap(tab(family.englishName(i)));
          await tester.pumpAndSettle();
          expect(find.text('${membershipCredits[i]} 点'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
      await tester.tap(find.text('切换为 Symphony'));
      await tester.pumpAndSettle();
      expect(find.text('方案已切换'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('membership-brand-logo')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('membership-tier-logo')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
