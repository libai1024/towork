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
            _fieldLabel(c, '图标'),
            const SizedBox(height: 8),
            _iconGrid(c),
            const SizedBox(height: 12),
            _fieldLabel(c, '颜色'),
            const SizedBox(height: 6),
            _colorPalette(c),
            const SizedBox(height: 12),
            _parentRow(c),
            if (_isEdit) ...[_archiveRow(c)],
            const SizedBox(height: 12),
            AppButton(
              label: '完  成',
              expand: true,
              enabled: _nameController.text.trim().isNotEmpty,
              onPressed: _saving ? null : _save,
              loading: _saving,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              AppPressable(
                onTap: () => Navigator.of(context).pop('delete'),
                semanticLabel: '删除此分类',
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(
                      '删除此分类',
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
            _isEdit ? '编辑分类' : '新建分类',
            style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
          ),
          const Spacer(),
          GlassIconButton(
            icon: LucideIcons.x,
            label: '关闭',
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
            decoration: const InputDecoration(hintText: '分类名称'),
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

  /// 24 图标策展集网格（6 列）：选中态 1px brand 描边 + 图标转 brand。
  Widget _iconGrid(AppColors c) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: ((constraints.maxWidth + 8) / 52).floor().clamp(
          1,
          MediaQuery.sizeOf(context).width >= 900 ? 8 : 6,
        ),
        mainAxisExtent: 44,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final option in categoryIconOptions)
            Semantics(
              label: '图标，${option.label}',
              selected: option.key == _iconKey,
              child: AppPressable(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _iconKey = option.key),
                child: AnimatedContainer(
                  duration: AppMotion.tabSwitch,
                  decoration: BoxDecoration(
                    color: c.fill1,
                    borderRadius: BorderRadius.circular(16),
                    border: option.key == _iconKey
                        ? Border.all(color: c.brand, width: 1)
                        : null,
                  ),
                  child: Icon(
                    option.icon,
                    size: 20,
                    color: option.key == _iconKey ? c.brand : c.labelSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 28px color swatches retain a 44px hit target.
  Widget _colorPalette(AppColors c) {
    final palette = categoryPaletteOf(c);
    return Wrap(
      runSpacing: 8,
      children: [
        for (var i = 0; i < palette.length; i++)
          Semantics(
            label:
                '颜色，${palette[i].name}，${_customColor == null && palette[i].key == _colorKey ? '已选中' : '未选中'}，共 ${palette.length} 项之第 ${i + 1} 项',
            child: AppPressable(
              minSize: 44,
              borderRadius: AppRadii.brFull,
              onTap: () => setState(() {
                _customColor = null;
                _colorKey = palette[i].key;
              }),
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: AnimatedScale(
                    scale: _customColor == null && palette[i].key == _colorKey
                        ? 1.1
                        : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette[i].color,
                        shape: BoxShape.circle,
                      ),
                      child: _customColor == null && palette[i].key == _colorKey
                          ? Icon(
                              LucideIcons.check,
                              size: 12,
                              color: categoryCheckColor(c, palette[i].color),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 归属选择行：含子分类的一级分类禁用（04 §3.4）；
  /// 「新建子分类」流程归属预选且锁定（04 §5.2）。
  Widget _parentRow(AppColors c) {
    final locked = widget.lockParent || _hasChildren;
    final repo = ref.watch(categoryListProvider.notifier);
    ref.watch(categoryListProvider);
    final parentName = _parentId == null
        ? '一级分类'
        : (repo.byId(_parentId)?.name ?? '一级分类');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPressable(
          onTap: locked ? null : _pickParent,
          behavior: HitTestBehavior.opaque,
          semanticLabel: '归属，$parentName',
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                Text(
                  '归属',
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
            '含子分类的分类不能再挂靠到其他分类下',
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
      title: '归属',
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _parentOption(null, '一级分类'),
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
      semanticLabel: '归属到$label',
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
                '归档此分类',
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
          '归档后不再出现在新建待办的分类列表中，数据保留',
          style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
        ),
      ],
    );
  }
}
