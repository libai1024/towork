import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_pressable.dart';
import '../../domain/update/release_history.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ReleaseNotes extends StatelessWidget {
  const ReleaseNotes({super.key, required this.notes});
  final List<String> notes;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final note in notes)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            note,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.of(context).labelSecondary,
            ),
          ),
        ),
    ],
  );
}

class ReleaseHistoryView extends StatefulWidget {
  const ReleaseHistoryView({
    super.key,
    required this.entries,
    required this.currentId,
    this.offeredId,
  });
  final List<ReleaseHistoryEntry> entries;
  final String currentId;
  final String? offeredId;
  @override
  State<ReleaseHistoryView> createState() => _ReleaseHistoryViewState();
}

class _ReleaseHistoryViewState extends State<ReleaseHistoryView> {
  String? expanded;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final current = widget.entries
        .where((e) => e.id == widget.currentId)
        .firstOrNull;
    final older = widget.entries.where(
      (e) => e != current && e.id != widget.offeredId,
    );
    final secondary = AppTextStyles.caption.copyWith(color: c.labelSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (current != null) ...[
          Text(context.strings.currentVersion, style: secondary),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.bgSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(current.label, style: AppTextStyles.title3),
                      Text(current.date, style: secondary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    current.titleFor(context.strings.localeName),
                    style: AppTextStyles.subhead,
                  ),
                  ReleaseNotes(
                    notes: current.notesFor(context.strings.localeName),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (older.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(context.strings.versionHistory, style: secondary),
          const SizedBox(height: 4),
          for (final entry in older) ...[
            AppPressable(
              semanticLabel:
                  '${expanded == entry.id ? context.strings.collapse : context.strings.expand} ${entry.label}',
              onTap: () => setState(
                () => expanded = expanded == entry.id ? null : entry.id,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.label,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            entry.titleFor(context.strings.localeName),
                            style: secondary,
                          ),
                        ],
                      ),
                    ),
                    Text(entry.date, style: secondary),
                    const SizedBox(width: 6),
                    Icon(
                      expanded == entry.id
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 15,
                      color: c.labelSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded == entry.id)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ReleaseNotes(
                  notes: entry.notesFor(context.strings.localeName),
                ),
              ),
            Divider(height: 1, color: c.separator),
          ],
        ],
      ],
    );
  }
}
