import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/app_chip.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/app_sheet.dart';
import 'package:towork/core/widgets/glass_surface.dart';
import 'package:towork/core/widgets/workspace_bottom_bar.dart';
import 'package:towork/core/widgets/workspace_nav_bar.dart';
import 'package:towork/features/settings/widgets/settings_shared.dart';
import 'package:towork/theme/app_spacing.dart';
import 'package:towork/theme/app_theme.dart';

Widget host(Widget child, {MediaQueryData? media, bool dark = false}) =>
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) =>
          MediaQuery(data: media ?? MediaQuery.of(context), child: child!),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets(
    'changing glass accessibility settings retains the live draft and focus',
    (tester) async {
      const editor = GlassSurface(child: TextField());
      await tester.pumpWidget(host(editor, media: const MediaQueryData()));
      await tester.enterText(find.byType(TextField), '准备预算明细');
      final initial = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      for (final media in [
        const MediaQueryData(accessibleNavigation: true),
        const MediaQueryData(highContrast: true),
        const MediaQueryData(),
      ]) {
        await tester.pumpWidget(host(editor, media: media));
        final current = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
        expect(current, same(initial));
        expect(current.widget.controller.text, '准备预算明细');
        expect(current.widget.focusNode.hasFocus, isTrue);
      }
    },
  );

  testWidgets(
    'glass preserves legibility for high contrast and accessible navigation',
    (tester) async {
      for (final media in [
        const MediaQueryData(highContrast: true),
        const MediaQueryData(accessibleNavigation: true),
      ]) {
        await tester.pumpWidget(
          host(const GlassSurface(child: Text('搜索')), media: media),
        );
        expect(
          find.byWidgetPredicate((w) => w is BackdropFilter && w.enabled),
          findsNothing,
        );
        expect(find.text('搜索'), findsOneWidget);
        final fills = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((box) => box.decoration)
            .whereType<ShapeDecoration>()
            .where((decoration) => decoration.color != null);
        expect(fills, isNotEmpty);
        expect(fills.every((decoration) => decoration.color!.a == 1), isTrue);
      }
    },
  );

  testWidgets(
    'action targets remain 44 points and loading prevents repeat submit',
    (tester) async {
      var submits = 0;
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(label: '保存', loading: true, onPressed: () => submits++),
              AppChip(label: '今天', onTap: () {}),
              GlassIconButton(
                icon: LucideIcons.plus,
                label: '新增',
                size: 32,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppChip)).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSize(find.byType(GlassIconButton)).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(submits, 0);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    },
  );

  testWidgets('settings toggle and option keep one clear interaction state', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsSwitch(
                value: value,
                semanticLabel: '允许提醒',
                onChanged: (next) => setState(() => value = next),
              ),
              SheetOptionRow(title: '语音', selected: true, onTap: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    expect(find.byType(Radio<Object>), findsNothing);
  });

  testWidgets(
    'mobile sheet stays above keyboard and closes only its nested route',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const media = MediaQueryData(
        size: Size(360, 740),
        padding: EdgeInsets.only(top: 24, bottom: 20),
        viewPadding: EdgeInsets.only(top: 24, bottom: 20),
        viewInsets: EdgeInsets.only(bottom: 260),
        textScaler: TextScaler.linear(1.6),
        disableAnimations: true,
      );
      String? result;
      await tester.pumpWidget(
        host(
          Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (pageContext) => Scaffold(
                body: Center(
                  child: TextButton(
                    child: const Text('打开'),
                    onPressed: () async {
                      result = await AppSheet.show<String>(
                        pageContext,
                        title: '默认输入方式',
                        child: SizedBox(
                          height: 600,
                          child: ListView(
                            children: [
                              const SizedBox(height: 400),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(pageContext).pop('saved'),
                                child: const Text('保存设置'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          media: media,
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('关闭'), findsOneWidget);
      expect(
        tester.getSize(find.byTooltip('关闭')).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getBottomLeft(find.byType(GlassSurface)).dy,
        lessThanOrEqualTo(480),
      );
      expect(tester.getTopLeft(find.byType(GlassSurface)).dx, greaterThan(0));
      await tester.scrollUntilVisible(
        find.text('保存设置'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('保存设置'));
      await tester.pumpAndSettle();
      expect(result, 'saved');
      expect(find.text('打开'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('titleless sheet does not duplicate a custom close control', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (pageContext) => TextButton(
            child: const Text('打开自定义'),
            onPressed: () => AppSheet.show<void>(
              pageContext,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassIconButton(
                    icon: LucideIcons.x,
                    label: '关闭',
                    onTap: () => Navigator.of(pageContext).pop(),
                  ),
                  const Text('自定义内容'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开自定义'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('自定义内容'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'glass keeps backdrop blur and continuous corners in normal contrast',
    (tester) async {
      await tester.pumpWidget(host(const GlassSurface(child: Text('内容'))));
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(ClipRSuperellipse), findsOneWidget);
    },
  );

  testWidgets('dark glass also drops blur and turns opaque for high contrast', (
    tester,
  ) async {
    for (final media in [
      const MediaQueryData(highContrast: true),
      const MediaQueryData(accessibleNavigation: true),
    ]) {
      await tester.pumpWidget(
        host(const GlassSurface(child: Text('导航')), dark: true, media: media),
      );
      expect(
        find.byWidgetPredicate((w) => w is BackdropFilter && w.enabled),
        findsNothing,
      );
      expect(find.byType(ClipRSuperellipse), findsOneWidget);
      final fills = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<ShapeDecoration>()
          .where((decoration) => decoration.color != null);
      expect(fills, isNotEmpty);
      expect(fills.every((decoration) => decoration.color!.a == 1), isTrue);
      expect(
        fills.every(
          (decoration) => decoration.shape is RoundedSuperellipseBorder,
        ),
        isTrue,
      );
    }
  });

  testWidgets(
    'shared controls show hover, focus, pressed states and keyboard activation',
    (tester) async {
      var activations = 0;
      await tester.pumpWidget(
        host(
          AppPressable(
            onTap: () => activations++,
            child: const Icon(Icons.add),
          ),
        ),
      );
      BoxDecoration? foreground() => tester
          .widgetList<Container>(find.byType(Container))
          .map((container) => container.foregroundDecoration)
          .whereType<BoxDecoration>()
          .first;
      // A key event switches the harness to traditional keyboard/mouse
      // highlights, matching a desktop session.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(AppPressable)));
      await tester.pumpAndSettle();
      expect(foreground()!.color, isNotNull, reason: 'hover state');
      Focus.maybeOf(tester.element(find.byIcon(Icons.add)))!.requestFocus();
      await tester.pumpAndSettle();
      expect(foreground()!.border, isNotNull, reason: 'focus state');
      final press = await tester.startGesture(
        tester.getCenter(find.byType(AppPressable)),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        AppMotion.pressOpacity,
        reason: 'pressed state',
      );
      await press.cancel();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(activations, 1);
    },
  );

  testWidgets('workspace bar and toolbar actions keep 44 point targets', (
    tester,
  ) async {
    final controller = TextEditingController(text: '关键词');
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WorkspaceToolbarAction(
              icon: LucideIcons.filter,
              label: '筛选',
              text: '筛选',
              onTap: () {},
            ),
            SizedBox(
              width: 320,
              child: WorkspaceBottomBar(
                searchController: controller,
                onSearchChanged: (_) {},
                onClear: () {},
                onAdd: () {},
              ),
            ),
          ],
        ),
      ),
    );
    for (final pressable in tester.widgetList<AppPressable>(
      find.byType(AppPressable),
    )) {
      final rect = tester.getRect(
        find.byWidgetPredicate((widget) => widget == pressable),
      );
      expect(
        rect.width,
        greaterThanOrEqualTo(44),
        reason: pressable.semanticLabel,
      );
      expect(
        rect.height,
        greaterThanOrEqualTo(44),
        reason: pressable.semanticLabel,
      );
    }
  });
}
