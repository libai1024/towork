import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/ai/brand_logos.dart';
import 'package:towork/core/ai/model_identity.dart';
import 'package:towork/domain/ai/model_gateway.dart';

void main() {
  test(
    'model identity distinguishes providers and unknown compatible routes',
    () {
      expect(brandOfModel('Kimi-K3'), AiBrand.kimi);
      expect(brandOfModel('DeepSeek-chat'), AiBrand.deepseek);
      expect(brandOfModel('GLM-5.3'), AiBrand.zhipu);
      expect(brandOfModel('claude-sonnet-4-5'), AiBrand.claude);
      expect(brandOfModel('gemini-2.5-pro'), AiBrand.gemini);
      expect(brandOfModel('gpt-4.1'), AiBrand.openai);
      expect(brandOfModel('o3-mini'), AiBrand.openai);
      expect(brandOfModel('private-route'), AiBrand.compatible);
      expect(brandOfProduct(ProviderKind.custom), AiBrand.compatible);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('brand assets decode at small and badge sizes in $brightness', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: Column(
                children: [
                  for (final brand in AiBrand.values)
                    Row(
                      children: [
                        BrandLogo(brand: brand, size: 14),
                        BrandLogo(brand: brand, size: 36, badge: true),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BrandLogo), findsNWidgets(AiBrand.values.length * 2));
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        return bytes;
      }))!;
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        expect(
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          reason: 'brand pixels are monochrome',
        );
        expect(bytes.getUint8(i + 1), bytes.getUint8(i + 2));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
