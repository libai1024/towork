import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/data/seeds/seed_palette.dart';
import 'package:towork/core/categories/category_catalog.dart';
import 'package:towork/theme/app_colors.dart';
import 'package:towork/theme/app_theme.dart';

/// Resolve each translucent layer before evaluating WCAG relative luminance.
double _contrast(Color ink, Color surface, Color canvas) {
  final background = Color.alphaBlend(surface, canvas);
  final foreground = Color.alphaBlend(ink, background);
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (math.max(a, b) + .05) / (math.min(a, b) + .05);
}

void _expectReadable(
  String description,
  Color ink,
  Color surface,
  Color canvas,
) {
  final ratio = _contrast(ink, surface, canvas);
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason:
        '$description: ${ratio.toStringAsFixed(2)}:1, expected at least 4.5:1',
  );
}

void main() {
  for (final (name, colors) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('C quiet $name', () {
      test('secondary labels remain readable on every daily text surface', () {
        final surfaces = {
          'bgGround': colors.bgGround,
          'bgPrimary': colors.bgPrimary,
          'bgSecondary': colors.bgSecondary,
          'bgTertiary': colors.bgTertiary,
          'fill1': colors.fill1,
          'fill2': colors.fill2,
        };
        final labels = {
          'labelSecondary': colors.labelSecondary,
          'labelTertiary': colors.labelTertiary,
          'labelQuaternary': colors.labelQuaternary,
        };
        for (final label in labels.entries) {
          for (final surface in surfaces.entries) {
            _expectReadable(
              '${label.key} on ${surface.key}',
              label.value,
              surface.value,
              colors.bgGround,
            );
          }
        }
      });

      test('overdue and primary actions have readable foregrounds', () {
        _expectReadable(
          'overdue badge',
          colors.overdueForeground,
          colors.overdueSurface,
          colors.bgGround,
        );
        _expectReadable(
          'inline overdue time',
          colors.overdueForeground,
          colors.bgGround,
          colors.bgGround,
        );
        for (final surface in {
          'brand': colors.brand,
          'brandHover': colors.brandHover,
          'brandActive': colors.brandActive,
        }.entries) {
          _expectReadable(
            'onBrand on ${surface.key}',
            colors.onBrand,
            surface.value,
            colors.bgGround,
          );
        }
      });

      test(
        'category ink stays readable for presets and existing custom hues',
        () {
          final inputs = <Color>[
            ...colors.categoryPalette,
            // Existing saved categories do not need a data migration.
            SeedPalette.brand,
            SeedPalette.red,
            SeedPalette.orange,
            SeedPalette.cyan,
            SeedPalette.green,
            SeedPalette.pink,
            SeedPalette.purple,
            Colors.black,
            Colors.white,
            Colors.grey,
            const Color(0x80456789),
            for (var hue = 0; hue < 360; hue += 15)
              HSLColor.fromAHSL(1, hue.toDouble(), .8, .5).toColor(),
          ];
          for (var index = 0; index < inputs.length; index++) {
            _expectReadable(
              'category input $index',
              colors.categoryForeground,
              colors.categorySurface(inputs[index]),
              colors.bgGround,
            );
          }
        },
      );

      test('selected editor swatches keep their checkmark readable', () {
        for (final option in categoryPaletteOf(colors)) {
          _expectReadable(
            'selected ${option.name} swatch',
            categoryCheckColor(colors, option.color),
            option.color,
            colors.bgGround,
          );
        }
      });

      test('category chart marks reach non-text contrast on primary surfaces', () {
        final colorsToCheck = [
          ...colors.categoryPalette,
          SeedPalette.brand,
          SeedPalette.red,
          SeedPalette.orange,
          SeedPalette.cyan,
          SeedPalette.green,
          SeedPalette.pink,
          SeedPalette.purple,
        ];
        for (var index = 0; index < colorsToCheck.length; index++) {
          for (final surface in {
            'bgGround': colors.bgGround,
            'bgPrimary': colors.bgPrimary,
            'bgSecondary': colors.bgSecondary,
            'bgTertiary': colors.bgTertiary,
          }.entries) {
            final ratio = _contrast(
              colors.categoryAccent(colorsToCheck[index]),
              surface.value,
              colors.bgGround,
            );
            expect(
              ratio,
              greaterThanOrEqualTo(3),
              reason:
                  'category accent $index on ${surface.key}: ${ratio.toStringAsFixed(2)}:1',
            );
          }
        }
      });
    });
  }

  for (final requestedMinimum in [24.0, 32.0]) {
    testWidgets(
      'a $requestedMinimum override cannot shrink an active touch target below 44',
      (tester) async {
        var activations = 0;
        const target = ValueKey('compact-action');
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: AppPressable(
                  key: target,
                  minSize: requestedMinimum,
                  onTap: () => activations++,
                  child: const Icon(Icons.undo, size: 18),
                ),
              ),
            ),
          ),
        );
        final bounds = tester.getRect(find.byKey(target));
        expect(bounds.width, greaterThanOrEqualTo(44));
        expect(bounds.height, greaterThanOrEqualTo(44));
        for (final point in [
          bounds.topLeft + const Offset(1, 1),
          bounds.topRight + const Offset(-1, 1),
          bounds.bottomLeft + const Offset(1, -1),
          bounds.bottomRight - const Offset(1, 1),
        ]) {
          await tester.tapAt(point);
          await tester.pumpAndSettle();
        }
        expect(activations, 4);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
