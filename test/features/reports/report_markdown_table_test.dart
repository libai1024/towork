import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/features/reports/widgets/report_markdown.dart';
import 'package:towork/theme/app_theme.dart';

const _content = '''
## 核心数据变动

| 项目 | 本期 | 上期 | 变动 |
| --- | --- | --- | --- |
| 账户总市值(元) | 1,234,567 | 987,654 | +24.9% |
| 完成待办(项) | 42 | 35 | +20% |

- 下周保持节奏
''';

const _tableScrollKey = ValueKey('report-markdown-table-scroll');

Widget _host({TextScaler textScaler = TextScaler.noScaling}) {
  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(child: ReportMarkdown(content: _content)),
    ),
  );
}

ScrollPosition _tableScrollPosition(WidgetTester tester) {
  final scrollable = find
      .descendant(
        of: find.byKey(_tableScrollKey),
        matching: find.byType(Scrollable),
      )
      .first;
  return tester.state<ScrollableState>(scrollable).position;
}

/// 表格里的文本一律不省略：完整内容始终在树中、可被无障碍朗读。
void _expectNoCellTruncation(WidgetTester tester, Finder root) {
  final cells = tester.widgetList<Text>(
    find.descendant(of: root, matching: find.byType(Text)),
  );
  expect(cells, isNotEmpty);
  for (final cell in cells) {
    expect(cell.maxLines, isNull, reason: '单元格不允许截断行数');
    expect(cell.overflow, isNot(TextOverflow.ellipsis), reason: '单元格不允许省略号');
  }
  expect(find.text('1,234,567'), findsOneWidget);
  expect(find.text('987,654'), findsOneWidget);
}

void main() {
  testWidgets('常规宽度：表格铺满视口、不引入横向滚动节点、全文在树中', (tester) async {
    await tester.pumpWidget(_host());

    // 放得下时不出现横向滚动（页面纵向 Scrollable 保持唯一）。
    expect(find.byKey(_tableScrollKey), findsNothing);
    expect(find.text('账户总市值(元)'), findsOneWidget);
    expect(find.text('+24.9%'), findsOneWidget);
    // 富余宽度按弹性比例分摊后，表格正好占满装饰边框的内沿（左右各 0.5px）。
    final decorated = find
        .ancestor(of: find.byType(Table), matching: find.byType(DecoratedBox))
        .first;
    final outerWidth = tester.getSize(decorated).width;
    expect(
      tester.getSize(find.byType(Table)).width,
      closeTo(outerWidth - 1.0, 0.5),
    );
    _expectNoCellTruncation(tester, find.byType(Table));
  });

  testWidgets('窄视口：表格横向可滚，单元格不省略、全文可访问', (tester) async {
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpWidget(_host());

    expect(find.byKey(_tableScrollKey), findsOneWidget);
    // 放不下的内容转为横向滚动，而不是省略号吞掉数据。
    expect(_tableScrollPosition(tester).maxScrollExtent, greaterThan(0));
    _expectNoCellTruncation(tester, find.byKey(_tableScrollKey));
  });

  testWidgets('大字号：表格横向可滚而非截断文本', (tester) async {
    await tester.pumpWidget(_host(textScaler: TextScaler.linear(2.0)));

    expect(find.byKey(_tableScrollKey), findsOneWidget);
    expect(_tableScrollPosition(tester).maxScrollExtent, greaterThan(0));
    _expectNoCellTruncation(tester, find.byKey(_tableScrollKey));
  });
}
