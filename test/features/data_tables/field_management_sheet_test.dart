import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/data_tables/data_table_detail_page.dart';
import 'package:towork/features/data_tables/widgets/field_management_sheet.dart';
import 'package:towork/theme/app_theme.dart';

final _now = DateTime(2026, 9, 24);

/// 演示模式（无 session）：内存 DataTableRepository 直接作为 dataTableProvider。
DataTableRepository _seededRepo() {
  final repo = DataTableRepository(
    initial: DataTableBundle(
      tables: [
        DataTableDef(
          id: 'table',
          name: '持仓',
          columns: [
            DataColumnDef(name: '名称', type: 'text', isRequired: true),
            DataColumnDef(name: '数量', type: 'number', unit: '股'),
          ],
          createdAt: _now,
        ),
      ],
      rows: [],
      logs: [],
    ),
  );
  repo.addRow('table', {'名称': '贵州茅台', '数量': '100'});
  repo.addRow('table', {'名称': '比亚迪', '数量': '200'});
  return repo;
}

Future<void> _mount(
  WidgetTester tester,
  DataTableRepository repo,
  Widget home,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(AppToast.dismiss);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dataTableProvider.overrideWith((ref) => repo)],
      child: MaterialApp(theme: AppTheme.light, home: home),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _launcher(void Function(BuildContext, WidgetRef) open) => Scaffold(
  body: Consumer(
    builder: (context, ref, _) => TextButton(
      onPressed: () => open(context, ref),
      child: const Text('打开'),
    ),
  ),
);

Finder _pressable(String semanticLabel) => find.byWidgetPredicate(
  (widget) => widget is AppPressable && widget.semanticLabel == semanticLabel,
);

void main() {
  testWidgets('打开面板列出字段名、类型与必填标记', (tester) async {
    final repo = _seededRepo();
    await _mount(
      tester,
      repo,
      _launcher(
        (context, ref) =>
            showFieldManagementSheet(context, ref, repo.tableById('table')!),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('管理字段'), findsOneWidget);
    expect(find.text('名称'), findsOneWidget);
    expect(find.text('数量'), findsOneWidget);
    expect(find.text('文本'), findsOneWidget);
    expect(find.text('数字（股）'), findsOneWidget);
    expect(find.text('必填'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('重命名后字段列表与页面列头同步更新', (tester) async {
    final repo = _seededRepo();
    await _mount(tester, repo, DataTableDetailPage(tableId: 'table'));
    // 记录卡片的摘要列头来自字段名。
    expect(find.text('数量'), findsNWidgets(2));

    await tester.tap(_pressable('表设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('管理字段'));
    await tester.pumpAndSettle();
    await tester.tap(_pressable('重命名「数量」'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      '持仓',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 面板列表更新（页面标题本身也叫「持仓」，此处只看字段行与旧名消失）。
    expect(find.text('数字（股）'), findsOneWidget);
    expect(find.text('数量'), findsNothing);
    // 演示仓库同步：字段重命名且行的值键跟随。
    final table = repo.tableById('table')!;
    expect(table.columns[1].name, '持仓');
    for (final row in repo.rowsOf('table')) {
      expect(row.values.containsKey('持仓'), isTrue);
      expect(row.values.containsKey('数量'), isFalse);
    }
    expect(rowValues(repo, '持仓'), unorderedEquals(['100', '200']));

    // 关闭面板后页面列头更新：标题 1 处 + 两张记录卡的列头。
    await tester.tap(_pressable('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('持仓'), findsNWidgets(3));
    expect(find.text('数量'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('添加可选字段成功并出现在列表中', (tester) async {
    final repo = _seededRepo();
    await _mount(
      tester,
      repo,
      _launcher(
        (context, ref) =>
            showFieldManagementSheet(context, ref, repo.tableById('table')!),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('添加字段'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '备注');
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();

    final table = repo.tableById('table')!;
    expect(table.columns, hasLength(3));
    expect(table.columns.last.name, '备注');
    expect(table.columns.last.isRequired, isFalse);
    // 可选字段不给现有行写值。
    for (final row in repo.rowsOf('table')) {
      expect(row.values.containsKey('备注'), isFalse);
    }
    expect(find.text('备注'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('必填字段缺补默认值时界面阻止提交；补值后原子写入全部行', (tester) async {
    final repo = _seededRepo();
    await _mount(
      tester,
      repo,
      _launcher(
        (context, ref) =>
            showFieldManagementSheet(context, ref, repo.tableById('table')!),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('添加字段'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '状态');
    await tester.tap(find.text('单选'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '待办，完成');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('将写入全部 2 行现有记录'), findsOneWidget);

    // 缺补默认值：界面报错、不发命令。
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();
    expect(find.text('必填字段需要为现有记录补一个值'), findsOneWidget);
    expect(repo.tableById('table')!.columns, hasLength(2));

    // 补值后提交成功，全部行拿到同一个默认值。
    await tester.enterText(find.byType(TextField).at(2), '待办');
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();

    final table = repo.tableById('table')!;
    expect(table.columns, hasLength(3));
    final status = table.columns.last;
    expect(status.name, '状态');
    expect(status.isRequired, isTrue);
    expect(status.enumOptions, equals(['待办', '完成']));
    expect(rowValues(repo, '状态'), unorderedEquals(['待办', '待办']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('删除字段确认影响后同步清除行数据', (tester) async {
    final repo = _seededRepo();
    await _mount(
      tester,
      repo,
      _launcher(
        (context, ref) =>
            showFieldManagementSheet(context, ref, repo.tableById('table')!),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.tap(_pressable('删除「数量」'));
    await tester.pumpAndSettle();
    expect(find.text('同时清除 2 行记录中的字段值。'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    final table = repo.tableById('table')!;
    expect(table.columns.map((c) => c.name), equals(['名称']));
    expect(rowValues(repo, '名称'), unorderedEquals(['贵州茅台', '比亚迪']));
    for (final row in repo.rowsOf('table')) {
      expect(row.values.containsKey('数量'), isFalse);
    }
    expect(find.text('数量'), findsNothing);
    expect(find.text('共 1 个字段'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

List<String> rowValues(DataTableRepository repo, String field) => [
  for (final row in repo.rowsOf('table')) row.values[field] ?? '',
];
