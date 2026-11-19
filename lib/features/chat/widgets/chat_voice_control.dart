import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../view_models/speech_capture_controller.dart';

String voiceControlLabel(SpeechPhase? phase, {bool keyboardEntry = false}) =>
    switch (phase) {
      SpeechPhase.requesting || SpeechPhase.starting => '准备录音中',
      SpeechPhase.recording => '正在录音',
      SpeechPhase.finalizing => '正在识别语音',
      SpeechPhase.pending => '语音待发送',
      SpeechPhase.submitting => '正在发送语音',
      _ => keyboardEntry ? '输入消息' : '按住说话',
    };

/// Touch holds and keyboard Space share release/cancel semantics. Screen readers
/// use an explicit toggle because their gestures don't expose a held pointer.
class ChatVoiceControl extends StatefulWidget {
  const ChatVoiceControl({
    super.key,
    required this.enabled,
    this.keyboardEntry = false,
    required this.phase,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
    required this.onCancel,
    required this.onTap,
    required this.onAccessibleActivate,
    required this.child,
  });
  final bool enabled, keyboardEntry;
  final SpeechPhase? phase;
  final VoidCallback onStart, onEnd, onCancel, onTap;
  final VoidCallback? onAccessibleActivate;
  final void Function(Offset origin, Offset delta) onMove;
  final Widget child;

  @override
  State<ChatVoiceControl> createState() => _ChatVoiceControlState();
}

class _ChatVoiceControlState extends State<ChatVoiceControl> {
  Offset _pressOrigin = Offset.zero;
  bool _keyHeld = false;
  bool _focused = false;

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event.logicalKey != LogicalKeyboardKey.space) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && !_keyHeld) {
      _keyHeld = true;
      widget.onStart();
    } else if (event is KeyUpEvent && _keyHeld) {
      _keyHeld = false;
      widget.onEnd();
    }
    return KeyEventResult.handled;
  }

  bool get _canActivate =>
      widget.phase == null || widget.phase == SpeechPhase.recording;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey('voice-input'),
    button: true,
    enabled: widget.enabled && _canActivate,
    label: voiceControlLabel(widget.phase, keyboardEntry: widget.keyboardEntry),
    hint: widget.phase == null
        ? (widget.keyboardEntry ? '点按输入，长按转文字' : '激活开始听写，或长按录音')
        : widget.phase == SpeechPhase.recording
        ? '激活结束录音，识别后发送'
        : '可取消语音输入或切换键盘',
    onTap: widget.enabled && _canActivate
        ? (widget.keyboardEntry ? widget.onTap : widget.onAccessibleActivate)
        : null,
    onLongPress: widget.enabled && _canActivate
        ? widget.onAccessibleActivate
        : null,
    excludeSemantics: true,
    child: Focus(
      onKeyEvent: _key,
      onFocusChange: (focused) {
        setState(() => _focused = focused);
        if (!focused && _keyHeld) {
          _keyHeld = false;
          widget.onCancel();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        onLongPressStart: widget.enabled
            ? (details) {
                final box = context.findRenderObject()! as RenderBox;
                _pressOrigin = box.localToGlobal(details.localPosition);
                widget.onStart();
              }
            : null,
        onLongPressMoveUpdate: widget.enabled
            ? (details) => widget.onMove(_pressOrigin, details.offsetFromOrigin)
            : null,
        onLongPressEnd: widget.enabled ? (_) => widget.onEnd() : null,
        onLongPressCancel: widget.enabled ? widget.onCancel : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: _focused
                ? Border.all(color: AppColors.of(context).labelPrimary)
                : null,
          ),
          child: widget.child,
        ),
      ),
    ),
  );
}
