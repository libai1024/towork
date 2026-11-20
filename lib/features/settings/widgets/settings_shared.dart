import 'package:towork/l10n/strings.dart';

import '../../../app/app_preferences_provider.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/workspace_nav_bar.dart';
import '../../../app/providers.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// 设置模块共享零件（09-settings-quota.md §3）：
/// 导航栏 / 组标题 / 分组卡片 / 设置行 / 开关 / Sheet 选项行。

/// Settings use the same navigation as the rest of the workspace.
class SettingsNavBar extends StatelessWidget {
  const SettingsNavBar({
    super.key,
    required this.title,
    required this.onBack,
    this.actions = const [],
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: WorkspaceNavBar(title: title, onBack: onBack, actions: actions),
    ),
  );
}

/// Group labels sit closer to their own rows than the preceding group.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({
    super.key,
    required this.label,
    this.topGap = 14,
  });

  final String label;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        topGap,
        AppSpacing.pageHorizontal,
        AppSpacing.xxs,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: c.labelSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Inset content groups stay solid; glass is reserved for navigation controls.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.children,
    this.dividerIndent = 38,
    this.footer,
    this.flat = false,
  });

  final List<Widget> children;

  /// Continuous settings rows share the page surface in the compact layout.
  final bool flat;

  final double dividerIndent;

  /// 卡内底部说明（`caption labelTertiary` 场景），上方带分割线。
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      decoration: flat
          ? null
          : ShapeDecoration(
              color: c.bgPrimary,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
      clipBehavior: flat ? Clip.none : Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (!flat && i > 0)
              Container(
                margin: EdgeInsets.only(left: dividerIndent),
                height: 0.5,
                color: c.separator,
              ),
            children[i],
          ],
          if (flat && footer == null)
            Container(height: 0.5, color: c.separator),
          if (footer != null) ...[
            Container(height: 0.5, color: c.separator),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Align(alignment: Alignment.centerLeft, child: footer!),
            ),
          ],
        ],
      ),
    );
  }
}

/// 设置行随内容增长，整行触控目标至少 44。
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.titleWeight = FontWeight.w400,
    this.value,
    this.valueColor,
    this.valueLeading,
    this.showChevron = false,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
    this.compact = false,
  });

  final IconData? icon;

  /// 自定义左侧（头像/状态点等），优先于 [icon]。
  final Widget? leading;
  final String title;

  /// 标题字重；用户卡行用 w500（subhead 感）。
  final FontWeight titleWeight;

  /// 右侧值（`footnote labelTertiary`）。
  final String? value;
  final Color? valueColor;
  final Widget? valueLeading;
  final bool showChevron;

  /// 自定义尾部（Switch/spinner/徽标组），与 value/chevron 并存时排在最后。
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final labelColor = enabled ? c.labelPrimary : c.labelQuaternary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AppPressable(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          semanticLabel: semanticLabel ?? title,
          child: Container(
            constraints: BoxConstraints(minHeight: compact ? 44 : 48),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 2 : AppSpacing.sm,
              vertical: 3,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ] else if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: enabled ? c.labelSecondary : c.labelQuaternary,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: labelColor,
                      fontWeight: titleWeight,
                    ),
                  ),
                ),
                ?valueLeading,
                if (value != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * .4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        value!,
                        style: AppTextStyles.footnote.copyWith(
                          color: valueColor ?? c.labelSecondary,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                if (showChevron) ...[
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: c.labelQuaternary,
                  ),
                ],
                ?trailing,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cupertino-shaped switches remain consistent on the Android preview too.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;

  /// 传 null 时渲染为禁用态（行级 enabled=false）。
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: semanticLabel,
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        thumbColor: value ? c.onBrand : c.bgPrimary,
        activeTrackColor: c.brand,
        inactiveThumbColor: c.bgPrimary,
        inactiveTrackColor: c.fill3,
        applyTheme: false,
      ),
    );
  }
}

/// 开关行（整行点按 == 切换开关的行专用）：
/// 把「行按钮 + CupertinoSwitch」合并成单一读屏焦点——一个带
/// label/toggled 的开关节点，双击即切换；行按钮与开关各自
/// 重复播报的问题不复存在。行的键盘焦点（Enter 激活）仍由内部
/// AppPressable 提供。
/// 行点按与开关指向不同操作（如「每日晨报」行打开时间选择）时，
/// 不要用本组件，继续用 [SettingsRow] + [SettingsSwitch]。
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.compact = false,
  });

  final IconData? icon;

  /// 自定义左侧（与 [SettingsRow.leading] 同义），优先于 [icon]。
  final Widget? leading;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: title,
      onTap: enabled ? () => onChanged(!value) : null,
      // 行内 AppPressable（按钮语义）与 CupertinoSwitch（开关语义）
      // 的播报被合并去重，只保留上面这一个开关节点。
      excludeSemantics: true,
      child: SettingsRow(
        icon: icon,
        leading: leading,
        title: title,
        enabled: enabled,
        compact: compact,
        onTap: enabled ? () => onChanged(!value) : null,
        trailing: SettingsSwitch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

/// Single-selection row: the trailing check is the only selection indicator.
class SheetOptionRow extends StatelessWidget {
  const SheetOptionRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.icon,
    this.leading,
    this.selected = false,
    this.locked = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String? subtitle;

  /// 说明文字色（如 自动执行档的 orange 警示），默认 `labelTertiary`。
  final Color? subtitleColor;

  /// 可选左侧线性图标（20px labelSecondary，与设置行同语法）。
  final IconData? icon;
  final Widget? leading;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = locked ? c.labelQuaternary : c.labelPrimary;

    return Semantics(
      selected: selected,
      child: AppPressable(
        onTap: locked ? null : onTap,
        onLongPress: locked ? null : onLongPress,
        behavior: HitTestBehavior.opaque,
        semanticLabel:
            '$title${selected ? context.strings.current : ''}${locked ? context.strings.locked : ''}',
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: locked ? c.labelQuaternary : c.labelSecondary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.footnote.copyWith(
                          color: locked
                              ? c.labelQuaternary
                              : (subtitleColor ?? c.labelTertiary),
                        ),
                      ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(LucideIcons.check, size: 20, color: c.brand),
              ] else if (locked) ...[
                const SizedBox(width: 8),
                Icon(LucideIcons.lock, size: 18, color: c.labelQuaternary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// AI 写入权限三档选择 Sheet（F6.3，设置首页与 AI 与额度页共用）。
void showAiWritePermissionSheet(BuildContext context, WidgetRef ref) {
  final c = AppColors.of(context);
  var saving = false;
  final current = ref.read(aiWritePermissionProvider);
  AppSheet.show<void>(
    context,
    title: context.strings.aiWritePermissions,
    child: StatefulBuilder(
      builder: (sheetContext, setSheetState) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in AiWritePermission.values)
              SheetOptionRow(
                title: localizedBuiltin(p.label),
                subtitle: localizedBuiltin(p.consequence),
                subtitleColor: c.labelSecondary,
                selected: p == current,
                onTap: () async {
                  if (saving) return;
                  setSheetState(() => saving = true);
                  final saved = await savePreferences(context, ref, {
                    'permission': p.name,
                  });
                  if (!sheetContext.mounted) return;
                  setSheetState(() => saving = false);
                  if (!saved) return;
                  Navigator.of(sheetContext).pop();
                  if (context.mounted) {
                    AppToast.show(
                      context,
                      message: context.strings.aiWritePermissionsSetTo(
                        localizedBuiltin(p.label),
                      ),
                    );
                  }
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                saving
                    ? context.strings.savingPermissions
                    : context.strings.tableEditsCanBeRevertedInRow,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
