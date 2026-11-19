import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/widgets/app_anchored_popover.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/features/chat/widgets/chat_input_bar.dart';
import 'package:towork/features/reports/widgets/report_common.dart';
import 'package:towork/features/visualization/widgets/viz_card.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Widget host(Widget child, {MediaQueryData? media}) => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) =>
          MediaQuery(data: media ?? MediaQuery.of(context), child: child!),
      home: Scaffold(body: child),
    ),
  );

  testWidgets(
    'model menu anchors below its trigger and fits a narrow safe area',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        host(
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => showChatModels(context, ref),
                  child: const Text('选择模型'),
                ),
              ),
            ),
          ),
          media: const MediaQueryData(
            size: Size(320, 700),
            padding: EdgeInsets.only(top: 32, bottom: 20),
            textScaler: TextScaler.linear(1.6),
            disableAnimations: true,
          ),
        ),
      );
      final trigger = tester.getRect(find.byType(TextButton));
      await tester.tap(find.text('选择模型'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final panel = tester.getRect(find.byKey(const ValueKey('model-picker')));
      expect(panel.top, closeTo(trigger.bottom + 8, .01));
      expect(panel.left, greaterThanOrEqualTo(12));
      expect(panel.right, lessThanOrEqualTo(308));
      expect(panel.bottom, lessThanOrEqualTo(668));
      expect(find.text('Kimi'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('provider-platform')));
      await tester.pumpAndSettle();
      expect(find.text('Kimi K3'), findsOneWidget);
      expect(find.text('快速'), findsOneWidget);
      expect(find.text('深度思考'), findsOneWidget);
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color?.a ?? 0, 0);
      await tester.tap(find.text('快速'));
      await tester.pumpAndSettle();
      expect(find.text('Kimi K3'), findsNothing);
      expect(find.text('选择模型'), findsOneWidget);
    },
  );

  testWidgets(
    'anchored menu moves above a low trigger and scrolls above keyboard',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.bottomLeft,
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppAnchoredPopover.show<void>(
                  context,
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      20,
                      (i) => SizedBox(height: 44, child: Text('选项 $i')),
                    ),
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
          media: const MediaQueryData(
            size: Size(320, 700),
            padding: EdgeInsets.only(top: 32),
            viewInsets: EdgeInsets.only(bottom: 280),
            disableAnimations: true,
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final panel = tester.getRect(find.byType(SingleChildScrollView));
      expect(panel.top, greaterThanOrEqualTo(40));
      expect(panel.bottom, lessThanOrEqualTo(408));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      expect(find.text('选项 19').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('compact chart segments retain distinct 44 point touch targets', (
    tester,
  ) async {
    var selected = '饼图';
    await tester.pumpWidget(
      host(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => VizMiniSegmented(
              options: const ['饼图', '柱图'],
              selected: selected,
              labelOf: (value) => value,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );
    for (final element in find.byType(AppPressable).evaluate()) {
      final rect = tester.getRect(find.byElementPredicate((e) => e == element));
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(rect.height, greaterThanOrEqualTo(44));
    }
    await tester.tap(find.text('柱图'));
    await tester.pumpAndSettle();
    expect(selected, '柱图');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'report typing indicator remains still when reduced motion is enabled',
    (tester) async {
      await tester.pumpWidget(
        host(
          const Center(child: PulsingDots()),
          media: const MediaQueryData(disableAnimations: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('press feedback is instant when animations are disabled', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        AppPressable(onTap: () => taps++, child: const Icon(Icons.check)),
        media: const MediaQueryData(disableAnimations: true),
      ),
    );
    await tester.tap(find.byType(AppPressable));
    await tester.pump();
    expect(taps, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
