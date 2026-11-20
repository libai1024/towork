import 'package:towork/l10n/strings.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';

/// 轻提示（规范 §4.6）：底部浮出胶囊，反色底 + 白字，r-full，
/// 2.5s 自动消失，可带一个操作按钮（如「撤销」「恢复」）。
class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  /// Capture application-owned presentation dependencies while a page exists.
  /// The returned callback can show feedback after that page closes, and safely
  /// becomes a no-op when the application's root overlay is disposed.
  static ValueChanged<String> presenter(BuildContext context) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final colors = AppColors.of(context);
    return (message) => _show(overlay, colors, message: message);
  }

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2500),
    bool completion = false,
  }) {
    _show(
      Overlay.of(context),
      AppColors.of(context),
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      completion: completion,
    );
  }

  /// Passive feedback centered in the visible viewport. The returned callback
  /// dismisses only this message if it is still visible.
  static VoidCallback showCentered(BuildContext context, String message) =>
      _show(
        Overlay.of(context, rootOverlay: true),
        AppColors.of(context),
        message: message,
        centered: true,
      );

  static VoidCallback _show(
    OverlayState overlay,
    AppColors colors, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2500),
    bool completion = false,
    bool centered = false,
  }) {
    if (!overlay.mounted) return () {};
    dismiss();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        colors: colors,
        duration: duration,
        completion: completion,
        centered: centered,
        onTimeout: () => _dismissIfCurrent(entry),
        message: message,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                _dismissIfCurrent(entry);
                onAction();
              },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    return () => _dismissIfCurrent(entry);
  }

  static void dismiss() {
    final entry = _current;
    _current = null;
    entry?.remove();
    entry?.dispose();
  }

  static void _dismissIfCurrent(OverlayEntry entry) {
    if (identical(_current, entry)) dismiss();
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.colors,
    required this.duration,
    required this.onTimeout,
    required this.message,
    required this.centered,
    this.actionLabel,
    this.onAction,
    this.completion = false,
  });

  final bool completion, centered;
  final AppColors colors;
  final Duration duration;
  final VoidCallback onTimeout;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onTimeout);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final media = MediaQuery.of(context);
    return Positioned(
      left: 16,
      right: 16,
      top: widget.centered ? 0 : null,
      bottom: widget.centered
          ? media.viewInsets.bottom
          : media.padding.bottom + 96,
      child: IgnorePointer(
        ignoring: widget.centered,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: widget.centered ? Offset.zero : const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                ),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.toastBackground,
                    borderRadius: AppRadii.brFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.completion)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ExcludeSemantics(
                            child: ScaleTransition(
                              scale: Tween<double>(begin: .8, end: 1).animate(
                                CurvedAnimation(
                                  parent: _controller,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.circleCheck,
                                size: 20,
                                color: c.onToast,
                              ),
                            ),
                          ),
                        ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              widget.message,
                              style: AppTextStyles.body.copyWith(
                                color: c.onToast,
                              ),
                              maxLines: widget.centered ? null : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null &&
                          widget.onAction != null) ...[
                        const SizedBox(width: 8),
                        AppPressable(
                          key: const ValueKey('toast-action'),
                          semanticLabel: widget.actionLabel,
                          borderRadius: AppRadii.brFull,
                          onTap: widget.onAction,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                widget.actionLabel!,
                                style: AppTextStyles.body.copyWith(
                                  color: c.onToast,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (!widget.centered)
                        AppPressable(
                          key: const ValueKey('toast-dismiss'),
                          semanticLabel: context.strings.dismiss,
                          borderRadius: AppRadii.brFull,
                          onTap: widget.onTimeout,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: c.onToast,
                            ),
                          ),
                        ),
                    ],
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
