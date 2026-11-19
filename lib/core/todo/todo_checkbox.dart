import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../widgets/app_pressable.dart';

/// Draws the check after the caller publishes a committed completion.
class TodoCheckbox extends StatefulWidget {
  const TodoCheckbox({
    super.key,
    required this.checked,
    this.onTap,
    this.size = 22,
    this.checkedColor,
    this.semanticLabel,
    this.animateOnMount = false,
  });

  final bool checked;
  final VoidCallback? onTap;
  final double size;
  final Color? checkedColor;
  final String? semanticLabel;
  final bool animateOnMount;

  @override
  State<TodoCheckbox> createState() => _TodoCheckboxState();
}

class _TodoCheckboxState extends State<TodoCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.checked && !widget.animateOnMount ? 1 : 0,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.checked ? 1 : 0;
    } else if (!_started && widget.checked && widget.animateOnMount) {
      _controller.forward();
    }
    _started = true;
  }

  @override
  void didUpdateWidget(TodoCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checked == widget.checked) return;
    if (widget.checked) HapticFeedback.selectionClick();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.checked ? 1 : 0;
    } else {
      widget.checked ? _controller.forward(from: 0) : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fill = widget.checkedColor ?? c.brand;
    final checkColor = widget.checkedColor == null
        ? c.onBrand
        : ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      checked: widget.checked,
      child: AppPressable(
        minSize: 48,
        onTap: widget.onTap,
        semanticLabel: widget.semanticLabel,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.checked ? fill : Colors.transparent,
                border: Border.all(
                  color: widget.checked ? fill : c.labelQuaternary,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: Curves.easeOutCubic.transform(
                        _controller.value,
                      ),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.check,
                    size: widget.size * .64,
                    color: checkColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
