import 'package:flutter/material.dart';

/// Lets messages pass beneath the composer while the final row stays reachable.
class ChatComposerLayout extends StatefulWidget {
  const ChatComposerLayout({
    super.key,
    required this.messages,
    required this.composer,
  });

  final Widget Function(double bottomPadding) messages;
  final Widget composer;

  @override
  State<ChatComposerLayout> createState() => _ChatComposerLayoutState();
}

class _ChatComposerLayoutState extends State<ChatComposerLayout> {
  final _composerKey = GlobalKey();
  double _height = 120;
  bool _scheduled = false;

  void _measure() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final height = _composerKey.currentContext?.size?.height;
      if (height != null && (height - _height).abs() > .5) {
        setState(() => _height = height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _measure();
    return Stack(
      children: [
        Positioned.fill(child: widget.messages(_height + 8)),
        Align(
          alignment: Alignment.bottomCenter,
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              _measure();
              return false;
            },
            child: SizeChangedLayoutNotifier(
              child: SizedBox(key: _composerKey, child: widget.composer),
            ),
          ),
        ),
      ],
    );
  }
}
