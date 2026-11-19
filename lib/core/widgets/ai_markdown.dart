import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'ai_code_block.dart';

/// AI 回复的 Markdown 渲染：标题/列表/粗斜体/行内代码/代码块/引用/链接/表格。
/// Streaming and saved replies use the same block layout.
class AiMarkdown extends StatelessWidget {
  const AiMarkdown({super.key, required this.text, this.baseStyle});

  final String text;
  final TextStyle? baseStyle;

  /// GFM：表格/删除线/任务列表；codeBlock/fence 已内建。
  static final md.ExtensionSet _set = md.ExtensionSet.gitHubFlavored;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final base =
        baseStyle ?? AppTextStyles.chatBody.copyWith(color: c.labelPrimary);
    return MarkdownBody(
      data: text,
      fitContent: true,
      selectable: false,
      extensionSet: _set,
      builders: {'pre': AiCodeBlockBuilder()},
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: base,
        listBullet: base.copyWith(color: c.labelTertiary),
        h1: base.copyWith(
          fontSize: 18,
          height: 26 / 18,
          fontWeight: FontWeight.w600,
        ),
        h2: base.copyWith(
          fontSize: 17,
          height: 25 / 17,
          fontWeight: FontWeight.w600,
        ),
        h3: base.copyWith(
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w600,
        ),
        h1Padding: const EdgeInsets.only(top: 8),
        h2Padding: const EdgeInsets.only(top: 8),
        h3Padding: const EdgeInsets.only(top: 8),
        h4: base.copyWith(fontWeight: FontWeight.w600),
        h5: base.copyWith(fontWeight: FontWeight.w600),
        h6: base.copyWith(fontWeight: FontWeight.w600),
        em: base.copyWith(fontStyle: FontStyle.italic),
        strong: base.copyWith(fontWeight: FontWeight.w600),
        blockquote: base.copyWith(color: c.labelSecondary),
        blockquoteDecoration: BoxDecoration(
          color: c.fill1,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        code: AppTextStyles.footnote.copyWith(
          color: c.labelPrimary,
          backgroundColor: c.fill1,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Menlo', 'Courier New'],
        ),
        codeblockDecoration: const BoxDecoration(),
        codeblockPadding: EdgeInsets.zero,
        tableHead: AppTextStyles.caption.copyWith(
          color: c.labelSecondary,
          fontWeight: FontWeight.w500,
        ),
        tableBody: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
        tableColumnWidth: const IntrinsicColumnWidth(),
        tableScrollbarThumbVisibility: true,
        tableBorder: TableBorder.all(
          color: c.separator,
          width: 0.5,
          borderRadius: BorderRadius.circular(8),
        ),
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 5,
        ),
        blockSpacing: 8,
        listIndent: 20,
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.separator, width: 0.5)),
        ),
      ),
    );
  }
}
