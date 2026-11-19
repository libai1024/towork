import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/core/widgets/app_chip.dart';
import 'package:towork/core/widgets/app_pressable.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/repositories/data_table_repository.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/features/data_tables/data_table_detail_page.dart';
import 'package:towork/features/data_tables/widgets/row_filter_sheet.dart';
import 'package:towork/theme/app_theme.dart';

final _now = DateTime(2026, 9, 24);

/// 覆盖全部字段类型的本地表（字段 ID 与 SQL 查询约定一致，非空）。
DataTableDef _filterableTable() => DataTableDef(
  id: 'table',
  name: '持仓',
  createdAt: _now,
  columns: [
    DataColumnDef(id: 'f_name', name: '名称', type: 'text'),
    DataColumnDef(id: 'f_qty', name: '数量', type: 'number', unit: '股'),
    DataColumnDef(id: 'f_amount', name: '金额', type: 'money', scale: 2),
    DataColumnDef(
      id: 'f_status',
      name: '状态',
      type: 'enum',
      enumOptions: ['待办', '完成'],
    ),
    DataColumnDef(id: 'f_date', name: '日期', type: 'date'),
    DataColumnDef(id: 'f_bool', name: '是否分红', type: 'bool'),
  ],
);

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
  return repo;
}

Finder _pressable(String semanticLabel) => find.byWidgetPredicate(
  (widget) => widget is AppPressable && widget.semanticLabel == semanticLabel,
);

Finder _chip(String label) => find.byWidgetPredicate(
  (widget) => widget is AppChip && widget.label == label,
);

Widget _sheetLauncher(
  DataTableDef table,
  void Function(List<RowFilterCondition>) recorder,
) => Scaffold(
  body: Builder(
    builder: (context) => TextButton(
      onPressed: () => showRowFilterSheet(
        context,
        table: table,
        initialConditions: const [],
        onApply: recorder,
      ),
      child: const Text('打开'),
    ),
  ),
);

Future<void> _openSheet(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: home));
  await tester.pumpAndSettle();
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('演示模式下表详情页不显示筛选条件入口', (tester) async {
    final repo = _seededRepo();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(AppToast.dismiss);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataTableProvider.overrideWith((ref) => repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DataTableDetailPage(tableId: 'table'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 投影列表行为不变：行卡片仍在。
    expect(find.text('贵州茅台'), findsOneWidget);
    // SQL 条件筛选入口隐藏；来源筛选与排序保留。
    expect(_pressable('筛选'), findsNothing);
    expect(_pressable('来源'), findsOneWidget);
    expect(_pressable('排序'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('条件增删与最多 4 条上限', (tester) async {
    await _openSheet(tester, _sheetLauncher(_filterableTable(), (_) {}));

    expect(find.text('按字段添加条件，最多 4 个'), findsOneWidget);
    final shortHeight = tester.getSize(find.byType(BottomSheet)).height;
    expect(shortHeight, lessThan(tester.view.physicalSize.height / 2));
    expect(find.text('添加条件'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.ensureVisible(find.text('添加条件'));
      await tester.tap(find.text('添加条件'));
      await tester.pumpAndSettle();
    }
    expect(find.byType(TextField), findsNWidgets(4));
    expect(
      tester.getSize(find.byType(BottomSheet)).height,
      greaterThan(shortHeight),
    );
    expect(_pressable('移除此条件'), findsNWidgets(4));
    expect(find.text('共 4 个条件'), findsOneWidget);
    // 达到上限后不再提供添加按钮，计数提示仍可见。
    expect(find.text('添加条件'), findsNothing);
    expect(find.text('共 4 个条件'), findsOneWidget);

    await tester.tap(_pressable('移除此条件').first);
    await tester.pumpAndSettle();
    expect(_pressable('移除此条件'), findsNWidgets(3));
    expect(find.text('添加条件'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('操作选项随字段类型变化，bool/enum 有专用控件', (tester) async {
    await _openSheet(tester, _sheetLauncher(_filterableTable(), (_) {}));

    await tester.tap(find.text('添加条件'));
    await tester.pumpAndSettle();

    // 默认选中首字段（文本）：等于 / 包含。
    expect(find.text('等于'), findsOneWidget);
    expect(find.text('包含'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // 数字字段：区间操作 + 数字键盘输入。
    await tester.tap(_chip('数量'));
    await tester.pumpAndSettle();
    expect(find.text('大于'), findsOneWidget);
    expect(find.text('大于等于'), findsOneWidget);
    expect(find.text('小于'), findsOneWidget);
    expect(find.text('小于等于'), findsOneWidget);
    expect(find.text('包含'), findsNothing);

    // 单选字段：选项 chips。
    await tester.tap(_chip('状态'));
    await tester.pumpAndSettle();
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // 布尔字段：只有等于，用开关取值（字段 chips 需横向滚动到位）。
    await tester.ensureVisible(_chip('是否分红'));
    await tester.tap(_chip('是否分红'));
    await tester.pumpAndSettle();
    expect(find.text('等于'), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('取值'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('数字校验拒绝非法输入并阻止应用', (tester) async {
    final applied = <List<RowFilterCondition>>[];
    await _openSheet(tester, _sheetLauncher(_filterableTable(), applied.add));

    await tester.tap(find.text('添加条件'));
    await tester.pumpAndSettle();
    await tester.tap(_chip('数量'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1..2');
    await tester.pumpAndSettle();
    expect(find.text('请输入数字'), findsOneWidget);

    await tester.tap(find.text('应用筛选'));
    await tester.pumpAndSettle();
    // 校验失败：面板保持打开且不回调。
    expect(find.text('应用筛选'), findsOneWidget);
    expect(applied, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('金额等值按精度规范化后回调', (tester) async {
    final applied = <List<RowFilterCondition>>[];
    await _openSheet(tester, _sheetLauncher(_filterableTable(), applied.add));

    await tester.tap(find.text('添加条件'));
    await tester.pumpAndSettle();
    await tester.tap(_chip('金额'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12.5');
    await tester.tap(find.text('应用筛选'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single, hasLength(1));
    final condition = applied.single.single;
    expect(condition.fieldId, 'f_amount');
    expect(condition.op, 'eq');
    // scale=2 的金额等值补齐为 canonical 两位小数。
    expect(condition.value, '12.50');
    expect(tester.takeException(), isNull);
  });

  testWidgets('文本包含与单选等值条件一起应用', (tester) async {
    final applied = <List<RowFilterCondition>>[];
    await _openSheet(tester, _sheetLauncher(_filterableTable(), applied.add));

    // 第一条：单选字段等值（此时仅一张条件卡，字段 chips 定位无歧义）。
    await tester.tap(find.text('添加条件'));
    await tester.pumpAndSettle();
    await tester.tap(_chip('状态'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('待办'));
    await tester.pumpAndSettle();

    // 第二条：默认名称字段，输入包含关键词。
    await tester.tap(find.text('添加条件'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' 茅台 ');
    // 先等输入触发的重建落盘，再点操作 chip，避免读到旧条件对象。
    await tester.pumpAndSettle();
    // 两张卡都有“包含”操作；第二张卡在树中靠后。
    await tester.tap(find.text('包含').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('应用筛选'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    final conditions = applied.single;
    final text = conditions.singleWhere((c) => c.fieldId == 'f_name');
    expect(text.op, 'contains');
    // 输入首尾空白被裁剪。
    expect(text.value, '茅台');
    final status = conditions.singleWhere((c) => c.fieldId == 'f_status');
    expect(status.op, 'eq');
    expect(status.value, '待办');
    expect(tester.takeException(), isNull);
  });

  testWidgets('未填值的条件不参与应用', (tester) async {
    final applied = <List<RowFilterCondition>>[];
    await _openSheet(tester, _sheetLauncher(_filterableTable(), applied.add));

    await tester.tap(find.text('添加条件'));
    await tester.pumpAndSettle();
    // 文本条件留空直接应用：等价于清除。
    await tester.tap(find.text('应用筛选'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('清除筛选回调空列表并关闭面板', (tester) async {
    final applied = <List<RowFilterCondition>>[];
    await _openSheet(tester, _sheetLauncher(_filterableTable(), applied.add));

    await tester.tap(find.text('清除筛选'));
    await tester.pumpAndSettle();

    expect(applied, hasLength(1));
    expect(applied.single, isEmpty);
    expect(find.text('清除筛选'), findsNothing);
    expect(find.text('打开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
