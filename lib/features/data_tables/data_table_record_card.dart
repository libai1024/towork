part of 'data_table_detail_page.dart';

/// 记录卡片（07-data-tables.md §3.2）：首字段为标题，至多 4 个摘要字段。
/// 投影列表与 SQL 结果模式共用；[updatedAt] 为空（SQL 预览无时间戳）时不显示更新时间。
class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.table,
    required this.values,
    required this.highlighted,
    required this.fromAi,
    required this.onTap,
    this.updatedAt,
    this.onLongPress,
  });

  final DataTableDef table;

  /// 列名 → 原始字符串值（bool 用 'true'/'false'，经 formatCellValue 展示）。
  final Map<String, String> values;
  final bool highlighted;
  final bool fromAi;
  final DateTime? updatedAt;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final firstField = table.columns.isEmpty ? null : table.columns.first;
    final title = firstField == null
        ? context.strings.recordBuild
        : (values[firstField.name] ?? '');
    final summaryColumns = table.columns.skip(1).take(4).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        // 高亮反馈在减弱动态效果时瞬时出现/消失。
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: highlighted ? c.brand25 : c.bgPrimary,
          borderRadius: AppRadii.brLg,
        ),
        child: AppPressable(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadii.brLg,
          semanticLabel: title,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? context.strings.untitled : title,
                        style: AppTextStyles.body.copyWith(
                          color: c.labelPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (fromAi) const AiBadge(),
                  ],
                ),
                if (summaryColumns.isNotEmpty) const SizedBox(height: 8),
                for (final column in summaryColumns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            column.name,
                            style: AppTextStyles.caption.copyWith(
                              color: c.labelTertiary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            formatCellValue(column, values[column.name]),
                            style: isNumericColumn(column)
                                ? tabularStyle(
                                    AppTextStyles.body.copyWith(
                                      color: c.labelPrimary,
                                    ),
                                  )
                                : AppTextStyles.body.copyWith(
                                    color: c.labelPrimary,
                                  ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (updatedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.strings.updated(relativeTime(updatedAt!)),
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
