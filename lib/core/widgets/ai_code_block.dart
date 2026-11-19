import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:markdown/markdown.dart' as md;

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_toast.dart';

class AiCodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  // flutter_markdown needs an inline child to close a final pre block.
  // The enclosing builder replaces this placeholder with the full code card.
  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) =>
      const SizedBox.shrink();

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.children?.whereType<md.Element>().firstOrNull;
    final language = (code?.attributes['class'] ?? '').replaceFirst(
      'language-',
      '',
    );
    return AiCodeBlock(code: element.textContent, language: language);
  }
}

class AiCodeBlock extends StatelessWidget {
  const AiCodeBlock({super.key, required this.code, this.language = ''});
  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.separator, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language.isEmpty ? '代码' : language,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '复制代码',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      AppToast.show(context, message: '已复制代码');
                    }
                  },
                  icon: Icon(
                    LucideIcons.copy,
                    size: 16,
                    color: c.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: .5, thickness: .5, color: c.separator),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: Text(
              code.endsWith('\n') ? code.substring(0, code.length - 1) : code,
              style: AppTextStyles.footnote.copyWith(
                height: 20 / 13,
                color: c.labelPrimary,
                fontFamily: 'monospace',
                fontFamilyFallback: const ['Menlo', 'Courier New'],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
