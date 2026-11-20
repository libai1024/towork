import 'package:towork/l10n/strings.dart';
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
  String date(DateTime d) =>
      context.strings.formattedValueDate(d.year, d.month, d.day);
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
    title: context.strings.memoryDetails,
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
            detail(context.strings.type, typeLabel),
            detail(
              context.strings.source,
              entry.source == MemorySource.manual
                  ? context.strings.addedManually
                  : context.strings.extractedByAi,
            ),
            detail(
              context.strings.confidenceShowmemorydetailsheet,
              '${localizedBuiltin(entry.confidenceLabel)} ${(entry.confidence * 100).round()}%',
            ),
            detail(
              context.strings.retention,
              entry.expiresAt == null
                  ? context.strings.noExpiration
                  : '${date(entry.expiresAt!)}${entry.isExpired(now) ? context.strings.expiredShowmemorydetailsheet : context.strings.expires}',
            ),
            detail(context.strings.create, date(entry.createdAt)),
            detail(context.strings.update, date(entry.updatedAt)),
            if (entry.sourceSessionId != null ||
                entry.sourceSessionTitle != null)
              AppPressable(
                semanticLabel: context.strings.openSourceChat(
                  entry.sourceSessionTitle ?? '',
                ),
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
                        context.strings.fromChatShowmemorydetailsheet(
                          entry.sourceSessionTitle ??
                              context.strings.viewOriginalChat,
                        ),
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
                  (
                    MemoryDetailAction.edit,
                    context.strings.edit,
                    LucideIcons.pencil,
                  ),
                  (
                    MemoryDetailAction.copy,
                    context.strings.copyShowmemorydetailsheet,
                    LucideIcons.copy,
                  ),
                  (
                    MemoryDetailAction.delete,
                    context.strings.deleteLabel,
                    LucideIcons.trash2,
                  ),
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
