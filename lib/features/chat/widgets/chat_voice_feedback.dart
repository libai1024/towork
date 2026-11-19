import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../view_models/speech_capture_controller.dart';
import 'chat_voice_control.dart';
import 'voice_gesture_geometry.dart';

export 'voice_gesture_geometry.dart' show VoiceZone, voiceZoneAt;

class VoiceRecordingPanel extends StatelessWidget {
  const VoiceRecordingPanel({
    super.key,
    required this.snapshot,
    required this.levels,
    required this.zone,
    required this.targets,
    required this.holding,
    required this.onActivate,
    required this.onCancel,
    required this.onEdit,
  });

  final SpeechCaptureState snapshot;
  final SpeechMeter levels;
  final VoiceZone zone;
  final GlobalKey targets;
  final bool holding;
  final VoidCallback onActivate;
  final VoidCallback? onCancel, onEdit;

  String get _caption => switch (snapshot.phase) {
    SpeechPhase.requesting || SpeechPhase.starting => '准备录音',
    SpeechPhase.submitting => '发送中',
    _ when holding => switch (zone) {
      VoiceZone.cancel => '松开取消',
      VoiceZone.revise => '松开编辑',
      VoiceZone.none => '松开发送',
    },
    SpeechPhase.finalizing => '正在识别',
    SpeechPhase.pending => '即将发送',
    _ => '结束录音',
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cancelling = zone == VoiceZone.cancel;
    final ink = cancelling ? colors.overdueForeground : colors.onBrand;
    final bubble = cancelling ? colors.overdueSurface : colors.brand;
    final veil = Color.lerp(
      colors.bgGround,
      colors.fill2,
      .38,
    )!.withValues(alpha: .91);
    final text = snapshot.text.trim();
    final listening = snapshot.phase == SpeechPhase.recording;
    return Material(
      key: const ValueKey('voice-live-panel'),
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final geometry = VoiceGestureGeometry(size);
          final small = size.height < 550;
          final font = small ? 17.0 : 20.0;
          final lineHeight =
              MediaQuery.textScalerOf(context).scale(font) * 1.38;
          return Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: '语音输入',
            child: GestureDetector(
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTapUp: (event) {
                if (holding) return;
                final point = event.localPosition;
                switch (geometry.hit(point)) {
                  case VoiceZone.cancel:
                    onCancel?.call();
                  case VoiceZone.revise:
                    onEdit?.call();
                  case VoiceZone.none:
                    if (listening && geometry.base.contains(point)) {
                      onActivate();
                    }
                }
              },
              child: Stack(
                key: targets,
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: veil),
                  CustomPaint(painter: _VoiceArcPainter(zone, colors)),
                  IgnorePointer(
                    child: Align(
                      alignment: const Alignment(0, -.07),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: math.min(size.width * .78, 460),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: small ? 17 : 23,
                              vertical: small ? 10 : 14,
                            ),
                            decoration: BoxDecoration(
                              color: bubble,
                              borderRadius: BorderRadius.circular(
                                small ? 18 : 22,
                              ),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: math.min(
                                  lineHeight * (small ? 2 : 4),
                                  size.height * .28,
                                ),
                              ),
                              child: SingleChildScrollView(
                                reverse: true,
                                physics: const NeverScrollableScrollPhysics(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (text.isEmpty && listening) ...[
                                      _Wave(color: ink, levels: levels),
                                      const SizedBox(width: 7),
                                    ],
                                    Flexible(
                                      child: Text(
                                        text.isEmpty
                                            ? (listening ? '正在听…' : '语音输入')
                                            : text,
                                        key: const ValueKey('voice-live-text'),
                                        style: AppTextStyles.chatInput.copyWith(
                                          color: ink,
                                          fontSize: font,
                                          height: 1.38,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: small ? 8 : 11),
                          Text(
                            _caption,
                            key: const ValueKey('voice-inline-status'),
                            style: AppTextStyles.footnote.copyWith(
                              color: cancelling
                                  ? colors.overdueForeground
                                  : colors.labelSecondary,
                              fontSize: small ? 13 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final left in [true, false])
                    Positioned(
                      left: geometry.labelX(left) - size.width * .16,
                      top: geometry.labelY - 22,
                      width: size.width * .32,
                      height: 44,
                      child: _WingLabel(
                        left: left,
                        selected: left
                            ? zone == VoiceZone.cancel
                            : zone == VoiceZone.revise,
                        action: left ? onCancel : onEdit,
                      ),
                    ),
                  Positioned(
                    top: geometry.crest,
                    bottom: 0,
                    left: size.width * .28,
                    right: size.width * .28,
                    child: Semantics(
                      key: const ValueKey('voice-input'),
                      container: true,
                      button: true,
                      enabled: listening,
                      label: voiceControlLabel(snapshot.phase),
                      hint: listening ? '激活结束录音，识别后发送' : '可取消语音输入或切换键盘',
                      onTap: listening ? onActivate : null,
                      onLongPress: listening ? onActivate : null,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WingLabel extends StatelessWidget {
  const _WingLabel({
    required this.left,
    required this.selected,
    required this.action,
  });
  final bool left, selected;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final label = left ? '取消语音输入' : '编辑转写';
    final content = Semantics(
      key: ValueKey(left ? 'voice-target-cancel' : 'voice-target-revise'),
      container: true,
      excludeSemantics: true,
      label: label,
      selected: selected,
      button: action != null,
      onTap: action,
      child: Center(
        child: Transform.rotate(
          angle: left ? -.14 : .14,
          child: Text(
            left ? '取消' : '编辑',
            key: left ? null : const ValueKey('switch-to-keyboard'),
            style: AppTextStyles.body.copyWith(
              color: selected ? colors.onBrand : colors.labelSecondary,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
    if (action == null) return content;
    return Tooltip(
      message: left ? label : '切换键盘输入',
      excludeFromSemantics: true,
      child: content,
    );
  }
}

class _VoiceArcPainter extends CustomPainter {
  const _VoiceArcPainter(this.zone, this.colors);
  final AppColors colors;
  final VoiceZone zone;

  @override
  void paint(Canvas canvas, Size size) {
    final g = VoiceGestureGeometry(size);
    final paint = Paint();
    for (final left in [true, false]) {
      final active = zone == (left ? VoiceZone.cancel : VoiceZone.revise);
      paint.color = active
          ? (left ? colors.overdueForeground : colors.brand)
          : colors.fill2;
      canvas.drawPath(g.wing(left), paint);
    }
    paint.color = colors.bgPrimary;
    paint.shader = ui.Gradient.linear(
      Offset(0, g.crest),
      Offset(0, size.height),
      [colors.separator, colors.bgSecondary, colors.bgPrimary],
      const [0, .025, 1],
    );
    canvas.drawPath(g.base, paint);
  }

  @override
  bool shouldRepaint(_VoiceArcPainter old) =>
      old.zone != zone || old.colors != colors;
}

class _Wave extends StatelessWidget {
  const _Wave({required this.color, required this.levels});
  final Color color;
  final SpeechMeter levels;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: 39,
        height: 22,
        child: AnimatedBuilder(
          animation: levels,
          builder: (context, _) {
            final samples = levels.samples;
            if (reduceMotion || samples.isEmpty) {
              return Icon(LucideIcons.mic, size: 17, color: color);
            }
            final bars = [...List.filled(9 - samples.length, 0.0), ...samples];
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final level in bars)
                  Container(
                    width: 2.5,
                    height: 3 + 18 * level,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
