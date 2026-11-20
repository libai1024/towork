part of 'field_management_sheet.dart';

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.column,
    required this.onRename,
    required this.onRemove,
  });

  final DataColumnDef column;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final typeLabel = fieldTypeName(column);
    final detail = column.unit == null
        ? typeLabel
        : '$typeLabel（${column.unit}）';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.bgPrimary,
        borderRadius: AppRadii.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          column.name,
                          style: AppTextStyles.body.copyWith(
                            color: c.labelPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (column.isRequired)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            context.strings.required,
                            style: AppTextStyles.caption.copyWith(color: c.red),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                ],
              ),
            ),
            AppPressable(
              onTap: onRename,
              semanticLabel: context.strings.renameBuild(column.name),
              borderRadius: AppRadii.brMd,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.pencil,
                  size: 18,
                  color: c.labelSecondary,
                ),
              ),
            ),
            AppPressable(
              onTap: onRemove,
              semanticLabel: context.strings.deleteLabelBuild2(column.name),
              borderRadius: AppRadii.brMd,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: c.labelSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 重命名字段对话框：沿用确认弹窗风格，非空校验，保存失败不关闭。
class _RenameFieldDialog extends StatefulWidget {
  const _RenameFieldDialog({required this.column, required this.onSave});

  final DataColumnDef column;
  final Future<bool> Function(String name) onSave;

  @override
  State<_RenameFieldDialog> createState() => _RenameFieldDialogState();
}

class _RenameFieldDialogState extends State<_RenameFieldDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.column.name,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() => _error = context.strings.fieldNameIsRequired);
      return;
    }
    if (name == widget.column.name) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final saved = await widget.onSave(name);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(name);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AbsorbPointer(
      absorbing: _saving,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.renameField,
              style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
            ),
            const SizedBox(height: 12),
            AppFieldLabel(
              label: context.strings.fieldNameBuildaddform,
              child: TextField(
                controller: _controller,
                enabled: !_saving,
                autofocus: true,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _save(),
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                decoration: InputDecoration(errorText: _error),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: context.strings.cancel,
                  type: AppButtonType.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: context.strings.save,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
