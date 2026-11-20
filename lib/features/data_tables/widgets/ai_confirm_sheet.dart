import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import 'badges.dart';
import 'confirm_dialog.dart';
import 'diff_card.dart';
import 'formatters.dart';
import 'repository_command.dart';
import 'mock_image_viewer.dart';

/// AI 写入确认弹窗（07-data-tables.md §3.5，三档权限共用形态）：
/// 来源说明 + 可勾选 diff 清单（删除类默认不勾选 + red 左边条）+ reason + 操作区。
class AiConfirmSheet extends StatefulWidget {
  const AiConfirmSheet({
    super.key,
    required this.table,
    required this.batch,
    required this.onApply,
    required this.onDiscard,
  });

  final DataTableDef table;
  final PendingAiBatch batch;

  /// 勾选集合确认后回调（父级负责落库与高亮）。
  final ValueChanged<Set<String>> onApply;
  final VoidCallback onDiscard;

  @override
  State<AiConfirmSheet> createState() => _AiConfirmSheetState();
}

class _AiConfirmSheetState extends State<AiConfirmSheet> {
  late final Set<String> _selected = {
    for (final change in widget.batch.changes)
      // 删除类默认不勾选，让用户多一次主动确认（§3.5）。
      if (change.action != DataChangeAction.delete) change.id,
  };

  DataColumnDef? _columnOf(String field) {
    for (final col in widget.table.columns) {
      if (col.name == field) return col;
    }
    return null;
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _discard() async {
    final hasDelete = widget.batch.changes.any(
      (c) => c.action == DataChangeAction.delete,
    );
    if (hasDelete) {
      final confirmed = await showAppConfirmDialog(
        context,
        title: context.strings.discardThisAnalysis,
        message: context.strings.includesOneDeletionDiscardingRemovesThisAi,
        confirmLabel: context.strings.discard,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    if (!mounted) return;
    if (!runRepositoryCommand(context, widget.onDiscard)) return;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final changes = widget.batch.changes;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 16, color: c.labelSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.strings.aiProposesChanges(changes.length),
                    style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
                  ),
                ),
                const AiBadge(),
              ],
            ),
            const SizedBox(height: 4),
            AppPressable(
              onTap: () =>
                  showMockImageViewer(context, label: widget.batch.sourceLabel),
              behavior: HitTestBehavior.translucent,

              semanticLabel: context.strings.viewSource,
              child: Text(
                context.strings.from(widget.batch.sourceLabel),
                style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
              ),
            ),
            const SizedBox(height: 12),
            // 变更清单
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: changes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final change = changes[i];
                  return _ConfirmChangeTile(
                    key: ValueKey('ai-change-${change.id}'),
                    table: widget.table,
                    change: change,
                    selected: _selected.contains(change.id),
                    onToggle: () => _toggle(change.id),
                    columnOf: _columnOf,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // reason 区
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.fill1,
                borderRadius: AppRadii.brMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.messageSquare,
                    size: 14,
                    color: c.labelSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.batch.reason,
                      style: AppTextStyles.footnote.copyWith(
                        color: c.labelSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 操作区
            Row(
              children: [
                AppButton(
                  label: context.strings.discard,
                  type: AppButtonType.ghost,
                  onPressed: _discard,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: context.strings.applySelected(_selected.length),
                    enabled: _selected.isNotEmpty,
                    expand: true,
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            if (!runRepositoryCommand(
                              context,
                              () => widget.onApply(Set.of(_selected)),
                            )) {
                              return;
                            }
                            if (mounted) Navigator.of(context).pop();
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmChangeTile extends StatelessWidget {
  const _ConfirmChangeTile({
    super.key,
    required this.table,
    required this.change,
    required this.selected,
    required this.onToggle,
    required this.columnOf,
  });

  final DataTableDef table;
  final PendingRowChange change;
  final bool selected;
  final VoidCallback onToggle;
  final DataColumnDef? Function(String field) columnOf;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final actionLabel = switch (change.action) {
      DataChangeAction.create => context.strings.add,
      DataChangeAction.update => context.strings.change,
      DataChangeAction.delete => context.strings.deleteLabel,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPressable(
          onTap: onToggle,
          behavior: HitTestBehavior.translucent,
          semanticLabel: selected
              ? context.strings.deselect
              : context.strings.selectLabelBuild,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? c.brand : Colors.transparent,
                borderRadius: AppRadii.brSm,
                border: Border.all(
                  color: selected ? c.brand : c.fill4,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Icon(LucideIcons.check, size: 14, color: c.onBrand)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DiffCard(
            header: '$actionLabel ${change.rowLabel}',
            danger: change.action == DataChangeAction.delete,
            children: [
              if (change.action == DataChangeAction.create)
                for (final e in change.createValues.entries)
                  FieldDiffLine(field: e.key, after: _format(e.key, e.value))
              else
                for (final f in change.fields)
                  FieldDiffLine(
                    field: f.field,
                    before: _format(f.field, f.oldValue),
                    after: change.action == DataChangeAction.delete
                        ? null
                        : _format(f.field, f.newValue),
                    lowConfidence: f.confidence < 0.8,
                  ),
            ],
          ),
        ),
      ],
    );
  }

  String? _format(String field, String? raw) {
    if (raw == null) return null;
    final col = columnOf(field);
    if (col == null) return raw;
    return formatCellValue(col, raw);
  }
}
