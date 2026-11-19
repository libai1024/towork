import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/todo/todo_utils.dart';

/// One quiet track and one moving selection, sized to its actual content.
/// Each label sits above its count, including zero. Dynamic Type determines
/// each segment's dimensions; narrow windows
/// scroll horizontally without reducing the 44-point targets.
class TodoQuickFilterBar extends StatefulWidget {
  const TodoQuickFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final TodoQuickFilter selected;
  final Map<TodoQuickFilter, int> counts;
  final ValueChanged<TodoQuickFilter> onChanged;

  @override
  State<TodoQuickFilterBar> createState() => _TodoQuickFilterBarState();
}

class _TodoQuickFilterBarState extends State<TodoQuickFilterBar> {
  static const _inset = 2.0;
  final _scroll = ScrollController();
  List<double> _widths = const [];
  bool _revealScheduled = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _revealSelection() {
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (!mounted || !_scroll.hasClients) return;
      final start = _widths
          .take(widget.selected.index)
          .fold(0.0, (sum, width) => sum + width);
      final end = start + _widths[widget.selected.index] + _inset * 2;
      final position = _scroll.position;
      final current = position.pixels;
      final target =
          (start < current
                  ? start
                  : end > current + position.viewportDimension
                  ? end - position.viewportDimension
                  : current)
              .clamp(position.minScrollExtent, position.maxScrollExtent);
      if ((target - current).abs() < .5) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: AppMotion.tabSwitch,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final media = MediaQuery.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final opaque = media.highContrast || media.accessibleNavigation;
    final direction = Directionality.of(context);
    final labelStyle = AppTextStyles.body.copyWith(fontWeight: FontWeight.w600);
    final countStyle = AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Size measure(String value, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: direction,
        textScaler: media.textScaler,
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      )..layout();
      final size = painter.size;
      painter.dispose();
      return size;
    }

    var targetHeight = 44.0;
    _widths = [
      for (final filter in TodoQuickFilter.values)
        (() {
          final label = measure(filter.label, labelStyle);
          final count = measure('${widget.counts[filter] ?? 0}', countStyle);
          targetHeight = math.max(
            targetHeight,
            label.height + count.height + 8,
          );
          return math.max(
            44.0,
            math.max(label.width, count.width).ceilToDouble() + 22,
          );
        })(),
    ];
    final contentWidth = _widths.fold(0.0, (sum, width) => sum + width);
    final selectionStart = _widths
        .take(widget.selected.index)
        .fold(0.0, (sum, width) => sum + width);
    final duration = media.disableAnimations
        ? Duration.zero
        : AppMotion.tabSwitch;
    const corners = BorderRadius.all(Radius.circular(999));

    return LayoutBuilder(
      builder: (context, constraints) {
        _revealSelection();
        final width = math.min(constraints.maxWidth, contentWidth + _inset * 2);
        final track = DecoratedBox(
          decoration: ShapeDecoration(
            color: c.fill1.withValues(alpha: opaque ? 1 : .62),
            shape: RoundedSuperellipseBorder(
              borderRadius: corners,
              side: BorderSide(
                color: opaque
                    ? c.labelSecondary
                    : c.separator.withValues(alpha: .38),
                width: opaque ? 1 : .5,
              ),
            ),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false),
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(_inset),
              child: SizedBox(
                width: contentWidth,
                height: targetHeight,
                child: Stack(
                  children: [
                    // One glass material (the blurred track) carries the
                    // control; the moving selection is a plain solid fill
                    // (VizMiniSegmented convention), never a second glass.
                    AnimatedPositionedDirectional(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      start: selectionStart,
                      top: 0,
                      bottom: 0,
                      width: _widths[widget.selected.index],
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: corners,
                            color: opaque
                                ? (dark ? c.bgTertiary : c.bgPrimary)
                                : (dark ? c.fill3 : c.bgPrimary),
                            border: Border.all(
                              color: opaque ? c.labelSecondary : c.separator,
                              width: opaque ? 1 : .5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final filter in TodoQuickFilter.values)
                          SizedBox(
                            width: _widths[filter.index],
                            height: targetHeight,
                            child: _segment(c, filter, labelStyle, countStyle),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: width,
            height: targetHeight + _inset * 2,
            child: ClipRSuperellipse(
              borderRadius: corners,
              child: opaque
                  ? track
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: track,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _segment(
    AppColors c,
    TodoQuickFilter filter,
    TextStyle labelStyle,
    TextStyle countStyle,
  ) {
    final selected = widget.selected == filter;
    final count = widget.counts[filter] ?? 0;
    final overdue = filter == TodoQuickFilter.overdue && count > 0;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AppPressable(
        semanticLabel: '按${filter.label}过滤，$count 项${selected ? '，已选中' : ''}',
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          if (!selected) widget.onChanged(filter);
        },
        child: Center(
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter.label,
                  style: labelStyle.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: overdue
                        ? c.overdueForeground
                        : selected
                        ? c.labelPrimary
                        : c.labelSecondary,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
                Text(
                  '$count',
                  style: countStyle.copyWith(
                    color: overdue ? c.overdueForeground : c.labelSecondary,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
