import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../widgets/glass_surface.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../widgets/app_button.dart';
import '../../widgets/app_pressable.dart';
import '../../widgets/app_sheet.dart';
import '../../../app/providers.dart';
import '../../workspace_actions.dart';
import '../../../domain/workspace/workspace_commands.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../category_catalog.dart';

part 'category_appearance_picker.dart';

/// 新建/编辑分类底部 Sheet（04-categories.md §3.4 / §5.3）。
/// 字段：预览 + 名称（20 字上限）、24 图标策展集、8 色盘、
/// 归属一级选择（二级 Sheet）、归档开关（仅编辑态）、删除（仅编辑态）。
class CategoryEditSheet extends ConsumerStatefulWidget {
  const CategoryEditSheet({
    super.key,
    this.editing,
    this.initialParentId,
    this.lockParent = false,
  });

  /// null = 新建。
  final Category? editing;

  /// 新建时预选归属；lockParent =「新建子分类」流程，归属锁定。
  final String? initialParentId;
  final bool lockParent;

  /// 新建：保存后返回新建的 Category；取消返回 null。
  static Future<Category?> showCreate(
    BuildContext context, {
    String? parentId,
    bool lockParent = false,
  }) {
    return AppSheet.show<Category>(
      context,
      child: CategoryEditSheet(
        initialParentId: parentId,
        lockParent: lockParent,
      ),
    );
  }

  /// 编辑：返回 'delete' 表示用户点了「删除此分类」，否则为 null。
  static Future<String?> showEdit(BuildContext context, Category category) {
    return AppSheet.show<String>(
      context,
      child: CategoryEditSheet(editing: category),
    );
  }

  @override
  ConsumerState<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<CategoryEditSheet> {
  late final TextEditingController _nameController;
  late String _iconKey;
  late String _colorKey;
  Color? _customColor;
  late String? _parentId;
  late bool _archived;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _iconKey = editing?.iconKey ?? 'folder';
    final presetColorKey = _colorKeyOf(editing?.color);
    _colorKey = presetColorKey ?? 'blue';
    _customColor = presetColorKey == null ? editing?.color : null;
    _parentId = editing?.parentId ?? widget.initialParentId;
    _archived = editing?.archived ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 按亮/暗两套色盘匹配色名（种子色取自亮盘，暗色模式下编辑也能正确预选）。
  void _selectIcon(String key) => setState(() => _iconKey = key);

  void _selectColor(String key) => setState(() {
    _customColor = null;
    _colorKey = key;
  });

  String? _colorKeyOf(Color? color) {
    if (color == null) return null;
    for (final palette in [
      categoryPaletteOf(AppColors.light),
      categoryPaletteOf(AppColors.dark),
    ]) {
      for (final option in palette) {
        if (option.color == color) return option.key;
      }
    }
    return null;
  }

  Color get _color {
    if (_customColor case final color?) return color;
    final c = AppColors.of(context);
    for (final option in categoryPaletteOf(c)) {
      if (option.key == _colorKey) return option.color;
    }
    return c.brand;
  }

  bool get _hasChildren {
    final editing = widget.editing;
    if (editing == null) return false;
    return ref
        .read(categoryListProvider.notifier)
        .childrenOf(editing.id)
        .isNotEmpty;
  }

  final _operationId = newWorkspaceId('category');
  bool _saving = false;
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (_saving || name.isEmpty) return;
    setState(() => _saving = true);
    final result = await workspaceUi(
      context,
      () => ref.read(workspaceUiCommandsProvider).run((todos, repo) {
        final editing = widget.editing;
        if (editing == null) {
          return repo.createCategory(
            name: name,
            color: _color,
            iconKey: _iconKey,
            parentId: _parentId,
          );
        }
        if (repo.byId(editing.id)?.version != editing.version) {
          throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
        }
        repo.updateCategory(
          editing.id,
          name: name,
          color: _color,
          iconKey: _iconKey,
        );
        if (_parentId != editing.parentId &&
            !repo.moveCategory(editing.id, _parentId, 9999)) {
          throw const WorkspaceFailure(WorkspaceFailureCode.validation);
        }
        if (_archived != editing.archived) {
          repo.setArchived(editing.id, _archived);
        }
        return repo.byId(editing.id)!;
      }, operationId: _operationId),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result != null) {
      Navigator.of(context).pop(widget.editing == null ? result.value : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AbsorbPointer(
      absorbing: _saving,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(c),
            const SizedBox(height: 8),
            _nameRow(c),
            const SizedBox(height: 12),
            _fieldLabel(c, context.strings.icon),
            const SizedBox(height: 8),
            _iconGrid(c),
            const SizedBox(height: 12),
            _fieldLabel(c, context.strings.color),
            const SizedBox(height: 6),
            _colorPalette(c),
            const SizedBox(height: 12),
            _parentRow(c),
            if (_isEdit) ...[_archiveRow(c)],
            const SizedBox(height: 12),
            AppButton(
              label: context.strings.done,
              expand: true,
              enabled: _nameController.text.trim().isNotEmpty,
              onPressed: _saving ? null : _save,
              loading: _saving,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              AppPressable(
                onTap: () => Navigator.of(context).pop('delete'),
                semanticLabel: context.strings.deleteCategory,
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(
                      context.strings.deleteCategory,
                      style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(AppColors c) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            _isEdit
                ? context.strings.editCategory
                : context.strings.newCategory,
            style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
          ),
          const Spacer(),
          GlassIconButton(
            icon: LucideIcons.x,
            label: context.strings.close,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 预览色块 + 名称输入框（04 §3.4：预览实时联动所选颜色与图标）。
  Widget _nameRow(AppColors c) {
    return Row(
      children: [
        AnimatedContainer(
          duration: AppMotion.tabSwitch,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.categorySurface(_color),
            borderRadius: AppRadii.brLg,
          ),
          child: Icon(
            categoryIconFor(_iconKey),
            size: 20,
            color: categoryIconColor(c, _color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _nameController,
            enabled: !_saving,
            maxLength: 20,
            autofocus: !_isEdit,
            style: AppTextStyles.body.copyWith(color: c.labelPrimary),
            onChanged: (_) => setState(() {}),
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) {
                  if (currentLength <= 15) return const SizedBox.shrink();
                  return Text(
                    '$currentLength/$maxLength',
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelQuaternary,
                    ),
                  );
                },
            decoration: InputDecoration(hintText: context.strings.categoryName),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(AppColors c, String label) {
    return Text(
      label,
      style: AppTextStyles.footnote.copyWith(
        color: c.labelSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 归属选择行：含子分类的一级分类禁用（04 §3.4）；
  /// 「新建子分类」流程归属预选且锁定（04 §5.2）。
  Widget _parentRow(AppColors c) {
    final locked = widget.lockParent || _hasChildren;
    final repo = ref.watch(categoryListProvider.notifier);
    ref.watch(categoryListProvider);
    final parentName = _parentId == null
        ? context.strings.topLevel
        : (repo.byId(_parentId)?.name ?? context.strings.topLevel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPressable(
          onTap: locked ? null : _pickParent,
          behavior: HitTestBehavior.opaque,
          semanticLabel: context.strings.parent(parentName),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                Text(
                  context.strings.parentParentrow,
                  style: AppTextStyles.body.copyWith(
                    color: locked ? c.labelQuaternary : c.labelPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  parentName,
                  style: AppTextStyles.footnote.copyWith(
                    color: locked ? c.labelQuaternary : c.labelSecondary,
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: c.labelTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_hasChildren)
          Text(
            context.strings.aCategoryWithSubcategoriesMustStayAt,
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
      ],
    );
  }

  /// 归属二级 Sheet（04 §5.3）：一级分类 + 各一级分类，当前值右侧 ✓。
  Future<void> _pickParent() async {
    final repo = ref.read(categoryListProvider.notifier);
    final candidates = repo.roots
        .where((e) => e.id != widget.editing?.id)
        .toList(growable: false);
    final selected = await AppSheet.show<String>(
      context,
      title: context.strings.parentParentrow,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _parentOption(null, context.strings.topLevel),
          for (final root in candidates) _parentOption(root.id, root.name),
        ],
      ),
    );
    // 取消返回 null；「选了一级分类」返回哨兵值，两者需区分。
    if (selected != null) {
      setState(() => _parentId = selected == _kRootSentinel ? null : selected);
    }
  }

  static const _kRootSentinel = '__root__';

  Widget _parentOption(String? parentId, String label) {
    final c = AppColors.of(context);
    final value = parentId ?? _kRootSentinel;
    final selected = _parentId == parentId;
    return AppPressable(
      onTap: () => Navigator.of(context).pop(value),
      behavior: HitTestBehavior.opaque,
      semanticLabel: context.strings.moveUnder(label),
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected) Icon(LucideIcons.check, size: 16, color: c.brand),
            ],
          ),
        ),
      ),
    );
  }

  /// 归档开关（仅编辑态，04 §3.4）。
  Widget _archiveRow(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Text(
                context.strings.archiveCategory,
                style: AppTextStyles.body.copyWith(color: c.labelPrimary),
              ),
              const Spacer(),
              CupertinoSwitch(
                value: _archived,
                activeTrackColor: c.brand,
                inactiveTrackColor: c.fill3,
                onChanged: (v) => setState(() => _archived = v),
              ),
            ],
          ),
        ),
        Text(
          context.strings.hidesThisCategoryWhenCreatingTasksIts,
          style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
        ),
      ],
    );
  }
}
