import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../domain/models/models.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// 相对时间（08-memory.md §3.5 元信息行）。
String relativeTimeLabel(DateTime time, DateTime now) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  if (diff.inDays < 30) return '${diff.inDays} 天前';
  return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
}

/// 记忆卡片（08-memory.md §3.5）：内容 / 徽标行 / 元信息行。
/// 交互：点击展开收起长文、长按弹操作菜单、左滑露出编辑/删除（§5.4）。
class MemoryCard extends StatefulWidget {
  const MemoryCard({
    super.key,
    required this.entry,
    required this.now,
    this.highlight = '',
    this.onEdit,
    this.onDelete,
    this.onCopy,
    this.onTapSession,
    this.onLongPressMenu,
  });

  final MemoryEntry entry;
  final DateTime now;

  /// 搜索关键词，命中片段以 brand 色高亮。
  final String highlight;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onTapSession;
  final VoidCallback? onLongPressMenu;

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard>
    with SingleTickerProviderStateMixin {
  static const double _kActionExtent = 152;

  late final AnimationController _swipeCtrl = AnimationController(
    vsync: this,
    duration: AppMotion.enter,
  );

  bool _expanded = false;

  double get _extent => _swipeCtrl.value * _kActionExtent;

  @override
  void dispose() {
    _swipeCtrl.dispose();
    super.dispose();
  }

  void _closeSwipe() =>
      _swipeCtrl.animateTo(0, duration: AppMotion.exit, curve: Curves.easeIn);

  void _onDragUpdate(DragUpdateDetails d) {
    final next = (_extent - d.delta.dx).clamp(0.0, _kActionExtent);
    _swipeCtrl.value = next / _kActionExtent;
  }

  void _onDragEnd(DragEndDetails d) {
    // 滑过半程松手直接触发删除确认（§5.4）。
    if (_extent >= _kActionExtent / 2) {
      _closeSwipe();
      widget.onDelete?.call();
    } else if (_extent >= 30) {
      _swipeCtrl.animateTo(1, duration: AppMotion.enter, curve: Curves.easeOut);
    } else {
      _closeSwipe();
    }
  }

  void _onTap() {
    if (_extent > 0) {
      _closeSwipe();
      return;
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final entry = widget.entry;
    final expired = entry.isExpired(widget.now);

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      onLongPress: widget.onLongPressMenu,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bgPrimary,
          borderRadius: AppRadii.brXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(c),
            const SizedBox(height: 8),
            _buildBadgeRow(c, expired),
            const SizedBox(height: 8),
            _buildMetaRow(c),
          ],
        ),
      ),
    );

    return Semantics(
      label:
          '${entry.typeLabel}记忆，${entry.content}，置信度${entry.confidenceLabel}'
          '${expired ? '，已过期' : ''}。双击展开，长按操作。',
      child: AnimatedBuilder(
        animation: _swipeCtrl,
        builder: (context, child) {
          return Stack(
            children: [
              if (_extent > 0)
                Positioned(
                  top: 0,
                  bottom: 12,
                  right: 16,
                  width: _kActionExtent,
                  child: _buildActions(c),
                ),
              Transform.translate(offset: Offset(-_extent, 0), child: child),
            ],
          );
        },
        child: card,
      ),
    );
  }

  Widget _buildContent(AppColors c) {
    final text = widget.entry.content;
    final style = AppTextStyles.body.copyWith(
      color: widget.entry.isExpired(widget.now)
          ? c.labelSecondary
          : c.labelPrimary,
    );
    final keyword = widget.highlight.trim();

    InlineSpan span;
    if (keyword.isEmpty) {
      span = TextSpan(text: text);
    } else {
      final spans = <TextSpan>[];
      final lower = text.toLowerCase();
      final key = keyword.toLowerCase();
      var start = 0;
      while (true) {
        final hit = lower.indexOf(key, start);
        if (hit < 0) {
          spans.add(TextSpan(text: text.substring(start)));
          break;
        }
        if (hit > start) spans.add(TextSpan(text: text.substring(start, hit)));
        spans.add(
          TextSpan(
            text: text.substring(hit, hit + keyword.length),
            style: TextStyle(color: c.brand, fontWeight: FontWeight.w500),
          ),
        );
        start = hit + keyword.length;
      }
      span = TextSpan(children: spans);
    }

    return Text.rich(
      span,
      style: style,
      maxLines: _expanded ? null : 3,
      overflow: _expanded ? null : TextOverflow.ellipsis,
    );
  }

  Widget _buildBadgeRow(AppColors c, bool expired) {
    final entry = widget.entry;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (entry.source == MemorySource.ai)
          _Badge(
            background: c.fill1,
            foreground: c.labelSecondary,
            icon: LucideIcons.sparkles,
            label: 'AI 提取',
          )
        else
          _Badge(
            background: c.fill1,
            foreground: c.labelSecondary,
            label: '手动',
          ),
        if (entry.isLowConfidence)
          _Badge(background: c.fill1, foreground: c.labelPrimary, label: '待确认')
        else
          Text(
            '置信度 ${entry.confidenceLabel}',
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
        if (expired)
          Text(
            '已过期',
            style: AppTextStyles.caption.copyWith(color: c.labelQuaternary),
          )
        else if (entry.isExpiringSoon(widget.now))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.hourglass, size: 12, color: c.labelSecondary),
              const SizedBox(width: 2),
              Text(
                '${entry.daysUntilExpiry(widget.now)} 天后失效',
                style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMetaRow(AppColors c) {
    final entry = widget.entry;
    final time = relativeTimeLabel(entry.updatedAt, widget.now);
    final hasSession =
        entry.source == MemorySource.ai && entry.sourceSessionTitle != null;

    return Row(
      children: [
        if (hasSession) ...[
          Flexible(
            child: AppPressable(
              onTap: widget.onTapSession,

              behavior: HitTestBehavior.translucent,
              semanticLabel: '跳转到来源会话 ${entry.sourceSessionTitle}',
              child: Text(
                '来自会话「${entry.sourceSessionTitle}」',
                style: AppTextStyles.caption.copyWith(color: c.brand),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Text(
            ' ',
            style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
          ),
        ],
        Text(
          time,
          style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
        ),
      ],
    );
  }

  Widget _buildActions(AppColors c) {
    Widget action({
      required Color background,
      required Color foreground,
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _closeSwipe();
            onTap?.call();
          },
          child: Container(
            color: background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: foreground),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(AppRadii.xl),
      ),
      child: Row(
        children: [
          action(
            background: c.fill3,
            foreground: c.labelPrimary,
            icon: LucideIcons.pencil,
            label: '编辑',
            onTap: widget.onEdit,
          ),
          action(
            background: c.fill1,
            foreground: c.labelPrimary,
            icon: LucideIcons.trash2,
            label: '删除',
            onTap: widget.onDelete,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.background,
    required this.foreground,
    required this.label,
    this.icon,
  });

  final Color background;
  final Color foreground;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: background, borderRadius: AppRadii.brXs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 2),
          ],
          Text(label, style: AppTextStyles.caption.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
