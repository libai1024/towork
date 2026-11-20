import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/glass_surface.dart';

/// Follows rendered content, including streaming text and async layout changes.
/// A user's scroll pauses following until they return or explicitly request it.
class ChatAutoScroll extends StatefulWidget {
  const ChatAutoScroll({
    super.key,
    required this.controller,
    required this.sessionId,
    required this.latestUserId,
    required this.child,
    this.bottomInset = 8,
  });
  final ScrollController controller;
  final String sessionId;
  final String? latestUserId;
  final Widget child;
  final double bottomInset;

  @override
  State<ChatAutoScroll> createState() => _ChatAutoScrollState();
}

class _ChatAutoScrollState extends State<ChatAutoScroll> {
  bool _following = true, _scheduled = false, _applying = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(ChatAutoScroll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.latestUserId != widget.latestUserId) {
      _following = true;
    }
    _schedule();
  }

  void _schedule() {
    if (!_following || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !_following || !widget.controller.hasClients) return;
      final position = widget.controller.position;
      if (!position.hasContentDimensions || position.extentAfter < .5) return;
      _applying = true;
      widget.controller.jumpTo(position.maxScrollExtent);
      _applying = false;
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || _applying) return false;
    if (notification is UserScrollNotification) {
      final following =
          notification.direction == ScrollDirection.idle &&
          notification.metrics.extentAfter < 80;
      if (_following != following) setState(() => _following = following);
      _schedule();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) _schedule();
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
        ),
        if (!_following)
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.bottomInset,
            child: Center(
              child: GlassIconButton(
                key: const ValueKey('chat-jump-latest'),
                icon: LucideIcons.arrowDown,
                iconSize: 18,
                label: context.strings.scrollToLatest,
                onTap: () {
                  setState(() => _following = true);
                  _schedule();
                },
              ),
            ),
          ),
      ],
    );
  }
}
