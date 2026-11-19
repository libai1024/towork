import 'package:flutter/material.dart';

/// Leaves the original press recognizer mounted while its feedback covers the
/// chat. A moving Quick Ask card supplies its own clipped viewport.
class ChatVoiceOverlay extends StatefulWidget {
  const ChatVoiceOverlay({
    super.key,
    this.boundary,
    required this.stage,
    required this.press,
    required this.changes,
  });
  final GlobalKey? boundary;
  final WidgetBuilder stage;
  final Widget press;
  final VoiceOverlayController changes;
  @override
  State<ChatVoiceOverlay> createState() => _ChatVoiceOverlayState();
}

class VoiceOverlayController extends ChangeNotifier {
  double? composerHeight;

  void refresh() => notifyListeners();
}

class _ChatVoiceOverlayState extends State<ChatVoiceOverlay> {
  OverlayEntry? _entry;
  Rect? _rect;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final overlay = Overlay.of(context);
      final boundary = widget.boundary?.currentContext?.findRenderObject();
      final root = overlay.context.findRenderObject();
      Rect? rect;
      if (boundary is RenderBox &&
          boundary.attached &&
          boundary.hasSize &&
          root is RenderBox) {
        rect =
            boundary.localToGlobal(Offset.zero, ancestor: root) & boundary.size;
      }
      if (_entry == null) {
        _rect = rect;
        final entry = OverlayEntry(
          builder: (_) => AnimatedBuilder(
            animation: widget.changes,
            builder: (context, _) {
              if (!mounted) return const SizedBox.shrink();
              final bounds = _rect;
              if (widget.boundary == null) {
                return Positioned.fill(child: widget.stage(context));
              }
              if (bounds == null) return const SizedBox.shrink();
              return Positioned(
                left: bounds.left,
                top: bounds.top,
                width: bounds.width,
                height: bounds.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: widget.stage(context),
                ),
              );
            },
          ),
        );
        _entry = entry;
        overlay.insert(entry);
      } else if (rect != _rect) {
        _rect = rect;
        widget.changes.refresh();
      }
      // Follow the sheet's entrance, rotation and IME motion on frames that
      // already exist. This callback does not request a frame while idle.
      if (widget.boundary != null) _schedule();
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.changes.composerHeight,
    child: Offstage(child: widget.press),
  );
}
