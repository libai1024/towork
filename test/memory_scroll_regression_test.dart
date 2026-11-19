import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/memory/memory_page.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  testWidgets('scrolling to an offscreen memory group preserves its entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const MemoryPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(MemoryPage)),
    );
    List<String> eventIds() => scope
        .read(memoryListProvider)
        .where((entry) => entry.type == MemoryType.event)
        .map((entry) => entry.id)
        .toList();
    final before = eventIds();
    expect(before, hasLength(4));
    await tester.dragUntilVisible(
      find.text('事件 4', findRichText: true),
      find.byKey(const ValueKey('memory-record-list')),
      const Offset(0, -200),
    );
    expect(find.text('事件 4', findRichText: true), findsOneWidget);
    expect(eventIds(), orderedEquals(before));
    await tester.dragUntilVisible(
      find.textContaining('天后失效'),
      find.byKey(const ValueKey('memory-record-list')),
      const Offset(0, -80),
    );
    expect(find.textContaining('天后失效'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
