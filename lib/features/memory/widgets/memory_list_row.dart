import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../domain/models/memory.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'memory_card.dart';

/// A compact solid content row; metadata and actions remain available in detail.
class MemoryListRow extends StatelessWidget {
  const MemoryListRow({
    super.key,
    required this.entry,
    required this.now,
    required this.onTap,
    required this.onLongPress,
    this.highlight = '',
  });
  final MemoryEntry entry;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String highlight;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final meta = [
      entry.source == MemorySource.manual ? '手动' : '会话',
      if (entry.isExpired(now))
        '已过期'
      else if (entry.isExpiringSoon(now))
        '${entry.daysUntilExpiry(now)} 天后失效'
      else if (entry.isLowConfidence)
        '待确认'
      else
        relativeTimeLabel(entry.updatedAt, now),
    ].join(' ');
    return AppPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: '记忆：${entry.content}，$meta',
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.separator)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    _content(c),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.footnote.copyWith(
                      color: c.labelPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronRight, size: 14, color: c.labelTertiary),
          ],
        ),
      ),
    );
  }

  TextSpan _content(AppColors colors) {
    final keyword = highlight.trim();
    final text = entry.content;
    if (keyword.isEmpty) return TextSpan(text: text);
    final start = text.toLowerCase().indexOf(keyword.toLowerCase());
    if (start < 0) return TextSpan(text: text);
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, start)),
        TextSpan(
          text: text.substring(start, start + keyword.length),
          style: TextStyle(
            color: colors.labelPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextSpan(text: text.substring(start + keyword.length)),
      ],
    );
  }
}
