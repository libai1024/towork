import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import 'report_common.dart';

/// 报告正文 Markdown 渲染（06-reports.md §3.3 渲染规格表）。
///
/// 支持：`##`/`###` 标题、段落、无序列表、表格（斑马纹 + 数字右对齐 +
/// 变动着色）、引用块、`---` 分隔线、`**加粗**`（含 +N%/-N% 涨跌着色）、
/// `` `行内代码` ``。
/// 「AI 观察与建议」使用中性引线与来源徽标，
/// 未命中降级为普通标题，不做脆弱解析。
class ReportMarkdown extends StatelessWidget {
  const ReportMarkdown({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildSections(context, blocks),
    );
  }

  // ---------------------------------------------------------------------------
  // 解析：行级块结构
  // ---------------------------------------------------------------------------

  static List<_Block> _parse(String content) {
    final blocks = <_Block>[];
    final para = <String>[];
    List<String>? bullets;
    List<String>? quote;
    List<String>? table;

    void flush() {
      if (para.isNotEmpty) {
        blocks.add(_Para(para.join(' ')));
        para.clear();
      }
      if (bullets != null) {
        blocks.add(_Bullets(bullets!));
        bullets = null;
      }
      if (quote != null) {
        blocks.add(_Quote(quote!));
        quote = null;
      }
      if (table != null) {
        final rows = table!
            .map(
              (line) => line
                  .trim()
                  .replaceAll(RegExp(r'^\|'), '')
                  .replaceAll(RegExp(r'\|$'), '')
                  .split('|')
                  .map((cell) => cell.trim())
                  .toList(),
            )
            .toList();
        // 去掉表头下的 --- 分隔行
        rows.removeWhere(
          (row) => row.every((cell) => RegExp(r'^:?-{2,}:?$').hasMatch(cell)),
        );
        if (rows.isNotEmpty) {
          blocks.add(_Table(rows.first, rows.skip(1).toList()));
        }
        table = null;
      }
    }

    for (final raw in content.split('\n')) {
      final line = raw.trimRight();
      if (line.startsWith('## ')) {
        flush();
        blocks.add(_H2(line.substring(3).trim()));
      } else if (line.startsWith('### ')) {
        flush();
        blocks.add(_H3(line.substring(4).trim()));
      } else if (line.startsWith('- ')) {
        if (para.isNotEmpty || quote != null || table != null) flush();
        (bullets ??= []).add(line.substring(2).trim());
      } else if (line.startsWith('> ')) {
        if (para.isNotEmpty || bullets != null || table != null) flush();
        (quote ??= []).add(line.substring(2).trim());
      } else if (line.startsWith('|')) {
        if (para.isNotEmpty || bullets != null || quote != null) flush();
        (table ??= []).add(line);
      } else if (line.trim() == '---') {
        flush();
        blocks.add(const _Divider());
      } else if (line.trim().isEmpty) {
        flush();
      } else {
        if (bullets != null || quote != null || table != null) flush();
        para.add(line.trim());
      }
    }
    flush();
    return blocks;
  }

  // ---------------------------------------------------------------------------
  // 渲染：按章节切分，AI 观察与建议走特殊排版
  // ---------------------------------------------------------------------------

  List<Widget> _buildSections(BuildContext context, List<_Block> blocks) {
    final widgets = <Widget>[];
    var currentH2 = '';
    var i = 0;
    while (i < blocks.length) {
      final block = blocks[i];
      if (block is _H2) {
        currentH2 = block.text;
        if (block.text.contains('AI 观察与建议')) {
          final inner = <_Block>[];
          i++;
          while (i < blocks.length && blocks[i] is! _H2) {
            inner.add(blocks[i]);
            i++;
          }
          widgets.add(_aiInsightSection(context, inner));
          continue;
        }
        widgets.add(_h2(context, block.text));
        i++;
        continue;
      }
      widgets.add(_renderBlock(context, block, currentH2));
      i++;
    }
    return widgets;
  }

  Widget _renderBlock(BuildContext context, _Block block, String currentH2) {
    return switch (block) {
      _H2() => _h2(context, block.text),
      _H3() => _h3(context, block.text),
      _Para() => _para(context, block.text),
      _Bullets() => _bullets(context, block.items, currentH2),
      _Quote() => _quote(context, block.lines.join(' ')),
      _Table() => _table(context, block),
      _Divider() => _divider(context),
    };
  }

  Widget _h2(BuildContext context, String text) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        text,
        style: AppTextStyles.subhead.copyWith(color: c.labelPrimary),
      ),
    );
  }

  Widget _h3(BuildContext context, String text) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: c.labelPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _para(BuildContext context, String text) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text.rich(
        TextSpan(
          children: _inlineSpans(
            context,
            text,
            AppTextStyles.callout.copyWith(color: c.labelPrimary),
          ),
        ),
      ),
    );
  }

  /// 列表：默认 4px 圆点；「逾期」节前置红圆点；「下期待办/关注」节前置空心方框（只读）。
  Widget _bullets(BuildContext context, List<String> items, String currentH2) {
    final c = AppColors.of(context);
    final isRisk = currentH2.contains('逾期');
    final isTodo = currentH2.contains('下期待办') || currentH2.contains('下月关注');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 16,
                    height: 21,
                    child: Center(
                      child: isRisk
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: c.overdueForeground,
                                shape: BoxShape.circle,
                              ),
                            )
                          : isTodo
                          ? Icon(
                              LucideIcons.square,
                              size: 16,
                              color: c.labelTertiary,
                            )
                          : Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: c.labelTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: _inlineSpans(
                          context,
                          item,
                          AppTextStyles.callout.copyWith(color: c.labelPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quote(BuildContext context, String text) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.separator, width: 2)),
      ),
      child: Text.rich(
        TextSpan(
          children: _inlineSpans(
            context,
            text,
            AppTextStyles.callout.copyWith(color: c.labelSecondary),
          ),
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      height: 0.5,
      color: c.separator,
    );
  }

  /// AI 洞察节：中性 2px 引线、来源徽标与内容缩进。
  Widget _aiInsightSection(BuildContext context, List<_Block> inner) {
    final c = AppColors.of(context);
    return Semantics(
      label: 'AI 生成内容',
      child: Container(
        margin: const EdgeInsets.only(top: 28, bottom: 12),
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.labelSecondary, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AiBadge(),
                const SizedBox(width: 8),
                Text(
                  'AI 洞察',
                  style: AppTextStyles.subhead.copyWith(color: c.labelPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 内层块去掉段落自身的下距差异，由小节统一控制
            for (final block in inner) _renderBlock(context, block, 'AI 观察与建议'),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 表格：表头 footnote 500 labelSecondary + 隔行 fill1 斑马纹；
  // 数字列右对齐 tabular figures；变动列靠正负号表达；外框 separator。
  // ---------------------------------------------------------------------------

  static final _numericCell = RegExp(r'^[+-]?[\d,]+(\.\d+)?[%\w一-龥]*$');
  static final _deltaCell = RegExp(r'^[+-][\d,]');

  String _stripBold(String cell) =>
      cell.startsWith('**') && cell.endsWith('**') && cell.length > 4
      ? cell.substring(2, cell.length - 2)
      : cell;

  Widget _table(BuildContext context, _Table table) {
    final c = AppColors.of(context);
    // 列对齐：数据行该列全部为数字形态 → 右对齐
    final colCount = table.header.length;
    if (colCount == 0) return const SizedBox.shrink();
    final alignRight = List.generate(colCount, (col) {
      if (table.rows.isEmpty) return false;
      return table.rows.every(
        (row) =>
            col < row.length && _numericCell.hasMatch(_stripBold(row[col])),
      );
    });

    TextStyle headerStyle = AppTextStyles.footnote.copyWith(
      color: c.labelSecondary,
      fontWeight: FontWeight.w500,
    );
    TextStyle cellStyle = AppTextStyles.footnote.copyWith(
      color: c.labelPrimary,
    );

    TextStyle styleFor(String plain, {required bool header, required int col}) {
      var style = header ? headerStyle : cellStyle;
      if (!header && _deltaCell.hasMatch(plain)) {
        style = style.copyWith(
          color: plain.startsWith('+') ? c.labelSecondary : c.labelPrimary,
          fontWeight: FontWeight.w500,
        );
      } else if (!header && alignRight[col]) {
        style = style.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        );
      }
      return style;
    }

    // 单元格不再 maxLines:1 + 省略号：放不下时换行增高，完整文本
    // 始终可读、可被无障碍朗读；行高由内容决定（下限 36 保持观感）。
    Widget cell(
      String text,
      int col, {
      required bool header,
      bool zebra = false,
    }) {
      final plain = _stripBold(text);
      return Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: zebra ? c.fill1 : null,
        alignment: alignRight[col]
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          plain,
          style: styleFor(plain, header: header, col: col),
        ),
      );
    }

    final rows = <TableRow>[
      TableRow(
        children: [
          for (var col = 0; col < colCount; col++)
            cell(table.header[col], col, header: true),
        ],
      ),
      for (var r = 0; r < table.rows.length; r++)
        TableRow(
          children: [
            for (var col = 0; col < colCount; col++)
              cell(
                col < table.rows[r].length ? table.rows[r][col] : '',
                col,
                header: false,
                zebra: r.isOdd,
              ),
          ],
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: c.separator, width: 0.5),
        borderRadius: AppRadii.brMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 各列自然宽度 = 单行排版宽度 + 左右 padding + 1px 余量。
          final widths = [
            for (var col = 0; col < colCount; col++)
              _columnNaturalWidth(context, table, col, styleFor),
          ];
          final total = widths.fold(0.0, (a, b) => a + b);
          final viewport = constraints.maxWidth;
          // 放得下：富余宽度按原弹性比例（首列 1.4、其余 1）分摊后直接铺满，
          // 视觉与旧的 FlexColumnWidth 实现一致，也不引入多余的可滚动节点；
          // 放不下（窄屏/大字号/超长数字）：保留自然宽度交给横向滚动，
          // 文本始终完整。
          final fits = viewport.isFinite && total <= viewport;
          if (fits) {
            final flexSum = 1.4 + (colCount - 1);
            final extra = viewport - total;
            for (var col = 0; col < colCount; col++) {
              widths[col] += extra * (col == 0 ? 1.4 : 1.0) / flexSum;
            }
          }
          final tableWidget = Table(
            columnWidths: {
              for (var col = 0; col < colCount; col++)
                col: FixedColumnWidth(widths[col]),
            },
            children: rows,
          );
          if (fits) {
            return SizedBox(width: viewport, child: tableWidget);
          }
          return SingleChildScrollView(
            key: const ValueKey('report-markdown-table-scroll'),
            scrollDirection: Axis.horizontal,
            child: tableWidget,
          );
        },
      ),
    );
  }

  double _columnNaturalWidth(
    BuildContext context,
    _Table table,
    int col,
    TextStyle Function(String plain, {required bool header, required int col})
    styleFor,
  ) {
    var widest = 0.0;
    final header = table.header[col];
    widest = math.max(
      widest,
      _singleLineWidth(
        context,
        _stripBold(header),
        styleFor(header, header: true, col: col),
      ),
    );
    for (final row in table.rows) {
      if (col >= row.length) continue;
      final plain = _stripBold(row[col]);
      widest = math.max(
        widest,
        _singleLineWidth(
          context,
          plain,
          styleFor(plain, header: false, col: col),
        ),
      );
    }
    return widest + 16 + 1;
  }

  /// 单行排版宽度（不换行、不用省略号），用于决定表格是否需要横向滚动。
  double _singleLineWidth(BuildContext context, String text, TextStyle style) {
    if (text.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.maxIntrinsicWidth;
    painter.dispose();
    return width;
  }

  // ---------------------------------------------------------------------------
  // 行内样式：加粗 / +N% -N% 涨跌着色 / 行内代码
  // ---------------------------------------------------------------------------

  static final _inlineToken = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`)');
  static final _deltaToken = RegExp(r'([+-]\d[\d,]*(?:\.\d+)?(?:%|pt)?)');

  List<InlineSpan> _inlineSpans(
    BuildContext context,
    String text,
    TextStyle base,
  ) {
    final c = AppColors.of(context);
    final spans = <InlineSpan>[];
    text.splitMapJoin(
      _inlineToken,
      onMatch: (m) {
        final s = m.group(0)!;
        if (s.startsWith('**')) {
          spans.addAll(_boldSpans(c, s.substring(2, s.length - 2), base));
        } else {
          // TODO: Geist Mono 字体 asset 未随本阶段内置，暂用系统等宽字体替代。
          spans.add(
            TextSpan(
              text: s.substring(1, s.length - 1),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: base.height,
                color: base.color,
                backgroundColor: c.fill1,
              ),
            ),
          );
        }
        return '';
      },
      onNonMatch: (s) {
        if (s.isNotEmpty) spans.add(TextSpan(text: s, style: base));
        return '';
      },
    );
    return spans;
  }

  /// 加粗段保留正负号与中性字重，避免把下降误用为警示色。
  List<InlineSpan> _boldSpans(AppColors c, String text, TextStyle base) {
    final bold = base.copyWith(fontWeight: FontWeight.w600);
    final spans = <InlineSpan>[];
    text.splitMapJoin(
      _deltaToken,
      onMatch: (m) {
        final s = m.group(0)!;
        spans.add(
          TextSpan(
            text: s,
            style: bold.copyWith(
              color: s.startsWith('+') ? c.labelSecondary : c.labelPrimary,
            ),
          ),
        );
        return '';
      },
      onNonMatch: (s) {
        if (s.isNotEmpty) spans.add(TextSpan(text: s, style: bold));
        return '';
      },
    );
    return spans;
  }
}

// ---------------------------------------------------------------------------
// 块结构
// ---------------------------------------------------------------------------

sealed class _Block {
  const _Block();
}

class _H2 extends _Block {
  const _H2(this.text);
  final String text;
}

class _H3 extends _Block {
  const _H3(this.text);
  final String text;
}

class _Para extends _Block {
  const _Para(this.text);
  final String text;
}

class _Bullets extends _Block {
  const _Bullets(this.items);
  final List<String> items;
}

class _Quote extends _Block {
  const _Quote(this.lines);
  final List<String> lines;
}

class _Table extends _Block {
  const _Table(this.header, this.rows);
  final List<String> header;
  final List<List<String>> rows;
}

class _Divider extends _Block {
  const _Divider();
}
