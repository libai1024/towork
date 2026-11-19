import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/models/memory.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

enum MemoryDetailAction { edit, copy, delete, source }

Future<MemoryDetailAction?> showMemoryDetailSheet(
  BuildContext context, {
  required MemoryEntry entry,
  required String typeLabel,
}) {
  final c = AppColors.of(context);
  final now = DateTime.now();
  String date(DateTime d) => '${d.year}年${d.month}月${d.day}日';
  Widget detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
          ),
        ),
      ],
    ),
  );
  return AppSheet.show<MemoryDetailAction>(
    context,
    title: '记忆详情',
    child: Builder(
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              entry.content,
              style: AppTextStyles.body.copyWith(color: c.labelPrimary),
            ),
            const SizedBox(height: 10),
            detail('类型', typeLabel),
            detail(
              '来源',
              entry.source == MemorySource.manual ? '手动添加' : 'AI 提取',
            ),
            detail(
              '置信度',
              '${entry.confidenceLabel} ${(entry.confidence * 100).round()}%',
            ),
            detail(
              '时效',
              entry.expiresAt == null
                  ? '长期有效'
                  : '${date(entry.expiresAt!)}${entry.isExpired(now) ? ' 已过期' : '失效'}',
            ),
            detail('创建', date(entry.createdAt)),
            detail('更新', date(entry.updatedAt)),
            if (entry.sourceSessionId != null ||
                entry.sourceSessionTitle != null)
              AppPressable(
                semanticLabel: '跳转到来源会话 ${entry.sourceSessionTitle ?? ''}',
                onTap: () =>
                    Navigator.pop(sheetContext, MemoryDetailAction.source),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.messageCircle,
                      size: 17,
                      color: c.labelSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '来自会话「${entry.sourceSessionTitle ?? '查看原会话'}」',
                        style: AppTextStyles.footnote.copyWith(
                          color: c.labelPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: c.labelSecondary,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final (action, label, icon) in [
                  (MemoryDetailAction.edit, '编辑', LucideIcons.pencil),
                  (MemoryDetailAction.copy, '复制', LucideIcons.copy),
                  (MemoryDetailAction.delete, '删除', LucideIcons.trash2),
                ])
                  Expanded(
                    child: AppPressable(
                      semanticLabel: label,
                      onTap: () => Navigator.pop(sheetContext, action),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 18, color: c.labelPrimary),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: AppTextStyles.footnote.copyWith(
                              color: c.labelPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
