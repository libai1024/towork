import '../../../app/business_ui_commands.dart';

import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../app/providers.dart';
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

/// 行变更历史（07-data-tables.md §3.4）：时间线倒序。
void showRowHistorySheet(
  BuildContext context, {
  required DataTableDef table,
  required DataRow row,
}) {
  AppSheet.show<void>(
    context,
    child: _RowHistorySheet(table: table, rowId: row.id),
  );
}

class _RowHistorySheet extends ConsumerWidget {
  const _RowHistorySheet({required this.table, required this.rowId});

  final DataTableDef table;
  final String rowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final bundle = ref.watch(dataTableProvider);
    final repo = ref.read(dataTableProvider.notifier);
    final logs = repo.logsOfRow(rowId);
    DataRow? row;
    for (final r in repo.rowsOf(table.id)) {
      if (r.id == rowId) row = r;
    }
    final rowLabel = row?.values[table.columns.firstOrNull?.name] ?? '这行记录';

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '变更历史',
                  style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rowLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: bundle.historyLoading
                ? const Center(
                    heightFactor: 1.6,
                    child: CircularProgressIndicator.adaptive(),
                  )
                : bundle.historyError
                ? Center(
                    heightFactor: 1.6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('暂时无法读取变更历史'),
                        AppButton(
                          label: '重试',
                          onPressed: () => ref.invalidate(dataTableProvider),
                        ),
                      ],
                    ),
                  )
                : logs.isEmpty
                ? Center(
                    heightFactor: 1.6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.history,
                          size: 32,
                          color: c.labelQuaternary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '暂无变更记录',
                          style: AppTextStyles.body.copyWith(
                            color: c.labelTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: logs.length,
                    itemBuilder: (context, i) => _HistoryEntry(
                      table: table,
                      log: logs[i],
                      isLast: i == logs.length - 1,
                      laterCount: repo.changesAfter(rowId, logs[i].createdAt),
                      onRollback: () => _rollback(context, ref, logs[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _rollback(
    BuildContext context,
    WidgetRef ref,
    DataChangeLog log,
  ) async {
    final repo = ref.read(dataTableProvider.notifier);
    final preview = repo
        .rowsOf(table.id)
        .where((r) => r.id == rowId)
        .firstOrNull;
    if (preview == null) return;
    final later = repo.changesAfter(rowId, log.createdAt);
    final time =
        '${log.createdAt.month}/${log.createdAt.day} ${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}';
    final confirmed = await showAppConfirmDialog(
      context,
      title: '回滚到这次修改？',
      message: later == 0
          ? '将回到 $time 的版本。回滚本身也会留下一条记录。'
          : '将回到 $time 的版本，此后的 $later 次变更也会被撤销。回滚本身也会留下一条记录。',
      confirmLabel: '回滚',
    );
    if (!confirmed || !context.mounted) return;
    if (!await runDataCommand(
      context,
      () => ref.read(businessUiCommandsProvider).restoreRow(preview, log),
    )) {
      return;
    }
    if (context.mounted) {
      AppToast.show(context, message: '已回滚到 $time 的版本');
    }
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({
    required this.table,
    required this.log,
    required this.isLast,
    required this.laterCount,
    required this.onRollback,
  });

  final DataTableDef table;
  final DataChangeLog log;
  final bool isLast;
  final int laterCount;
  final VoidCallback onRollback;

  DataColumnDef? _columnOf(String field) {
    for (final col in table.columns) {
      if (col.name == field) return col;
    }
    return null;
  }

  String _format(String field, String? raw) {
    if (raw == null) return '';
    final col = _columnOf(field);
    return col == null ? raw : formatCellValue(col, raw);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isAi = log.source == DataChangeSource.ai;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 时间线：节点圆点 + 竖线
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isAi ? c.labelSecondary : c.labelTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: c.separator)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 条目头：时间 actor + 回滚
                  Row(
                    children: [
                      Text(
                        relativeTime(log.createdAt),
                        style: AppTextStyles.footnote.copyWith(
                          color: c.labelTertiary,
                        ),
                      ),
                      Text(
                        ' ',
                        style: AppTextStyles.footnote.copyWith(
                          color: c.labelQuaternary,
                        ),
                      ),
                      if (isAi)
                        const AiBadge()
                      else
                        Text(
                          '我',
                          style: AppTextStyles.footnote.copyWith(
                            color: c.labelPrimary,
                          ),
                        ),
                      const Spacer(),
                      if (log.action != DataChangeAction.delete)
                        AppButton(
                          label: '回滚',
                          type: AppButtonType.ghost,
                          onPressed: onRollback,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildDiffCard(c),
                  if (isAi && log.reason != null) ...[
                    const SizedBox(height: 8),
                    _ReasonBubble(
                      reason: log.reason!,
                      sourceLabel: log.sourceLabel,
                      onViewSource: log.sourceLabel == null
                          ? null
                          : () => showMockImageViewer(
                              context,
                              label: log.sourceLabel!,
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffCard(AppColors c) {
    switch (log.action) {
      case DataChangeAction.create:
        return DiffCard(
          children: [
            Text(
              '新建了这行',
              style: AppTextStyles.body.copyWith(color: c.labelSecondary),
            ),
            const SizedBox(height: 4),
            for (final e in (log.afterValues ?? const {}).entries)
              FieldDiffLine(field: e.key, after: _format(e.key, e.value)),
          ],
        );
      case DataChangeAction.delete:
        return DiffCard(
          danger: true,
          children: [
            Text(
              '删除了这行',
              style: AppTextStyles.body.copyWith(color: c.labelPrimary),
            ),
            const SizedBox(height: 4),
            for (final e in (log.beforeValues ?? const {}).entries)
              FieldDiffLine(field: e.key, before: _format(e.key, e.value)),
          ],
        );
      case DataChangeAction.update:
        if (log.beforeValues != null && log.afterValues != null) {
          return DiffCard(
            children: [
              for (final key in {
                ...log.beforeValues!.keys,
                ...log.afterValues!.keys,
              })
                FieldDiffLine(
                  field: key,
                  before: _format(key, log.beforeValues![key]),
                  after: _format(key, log.afterValues![key]),
                ),
            ],
          );
        }
        return DiffCard(
          children: [
            FieldDiffLine(
              field: log.field,
              before: _format(log.field, log.oldValue),
              after: _format(log.field, log.newValue),
            ),
          ],
        );
    }
  }
}

class _ReasonBubble extends StatelessWidget {
  const _ReasonBubble({
    required this.reason,
    this.sourceLabel,
    this.onViewSource,
  });

  final String reason;
  final String? sourceLabel;
  final VoidCallback? onViewSource;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.messageSquare, size: 14, color: c.labelSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: AppTextStyles.footnote.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
                if (sourceLabel != null) ...[
                  const SizedBox(height: 4),
                  AppPressable(
                    onTap: onViewSource,
                    behavior: HitTestBehavior.translucent,

                    semanticLabel: '查看原图',
                    child: Text(
                      '$sourceLabel 查看原图 ▸',
                      style: AppTextStyles.footnote.copyWith(color: c.brand),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
