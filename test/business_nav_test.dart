import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/widgets/workspace_nav_bar.dart';
import 'package:towork/core/widgets/workspace_bottom_bar.dart';
import 'package:towork/core/widgets/workspace_scope_rail.dart';
import 'package:towork/features/data_tables/data_tables_page.dart';
import 'package:towork/features/memory/memory_page.dart';
import 'package:towork/features/reports/reports_page.dart';
import 'package:towork/features/todo/todo_list_page.dart';
import 'package:towork/features/visualization/visualization_page.dart';
import 'package:towork/theme/app_theme.dart';

Future<void> _mount(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: page),
    ),
  );
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('business navigation fits a narrow phone across all workflows', (
    tester,
  ) async {
    for (final page in <Widget>[
      const TodoListPage(),
      const VisualizationPage(),
      const ReportsPage(),
      const DataTablesPage(),
      const MemoryPage(),
    ]) {
      await _mount(tester, page);
      expect(find.byType(WorkspaceNavBar), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
    }
  });

  testWidgets('memory search clear cancels its pending debounce', (
    tester,
  ) async {
    await _mount(tester, const MemoryPage());
    final search = find.descendant(
      of: find.byType(WorkspaceBottomBar),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, '茅台');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('清除搜索'));
    await tester.pump(const Duration(milliseconds: 400));
    // The index counts follow the effective query, so a stale timer would
    // reduce the all count to 1 even though the text field had been cleared.
    final scopes = tester.widget<WorkspaceScopeRail>(
      find.byType(WorkspaceScopeRail),
    );
    expect(scopes.items.singleWhere((item) => item.id == 'all').count, 12);
    expect(scopes.items.singleWhere((item) => item.id == 'event').count, 4);
    expect(find.text('事件 1'), findsNothing);
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(find.byType(WorkspaceNavBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
