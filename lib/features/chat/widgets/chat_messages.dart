import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/reply_copy_button.dart';

import 'package:intl/intl.dart';

import '../../../domain/models/models.dart';

export 'ai_todo_card.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/ai_markdown.dart';
import '../../../theme/app_text_styles.dart';

/// 截止时间展示：今天 15:00 / 明天 15:00 / 9月24日 09:00。
String formatDue(DateTime due) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(due.year, due.month, due.day);
  final time = DateFormat('HH:mm').format(due);
  if (day == today) return strings.todayRelativetimelabel(time);
  if (day == today.add(const Duration(days: 1))) {
    return strings.tomorrowFormatdue(time);
  }
  if (day == today.add(const Duration(days: 2))) {
    return strings.dayAfterTomorrow(time);
  }
  return strings.formattedValueExportlabel(due.month, due.day, time);
}

/// 相对时间：09:12 / 昨天 / 周三 / 9月18日。
String formatRelative(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  if (day == today) return DateFormat('HH:mm').format(time);
  if (day == today.subtract(const Duration(days: 1))) {
    return strings.yesterdayGroup;
  }
  final diff = today.difference(day).inDays;
  if (diff < 7) {
    final names = [
      strings.monFormatrelative,
      strings.tueFormatrelative,
      strings.wedFormatrelative,
      strings.thuFormatrelative,
      strings.friFormatrelative,
      strings.satFormatrelative,
      strings.sun,
    ];
    return names[time.weekday - 1];
  }
  return strings.formattedValue(time.month, time.day);
}

/// 用户消息气泡：fill1 底 r-xl，右对齐，最大宽 78%。
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: c.fill1,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: AppTextStyles.chatBody.copyWith(color: c.labelPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// AI 文本消息：无气泡底，来源不使用额外色彩编码。
/// content 为空 = 首 token 前的三点脉冲「正在想…」；
/// streaming = true 时末尾带呼吸光标。
class AiTextMessage extends StatelessWidget {
  const AiTextMessage({
    super.key,
    required this.message,
    this.streaming = false,
    this.showActions = true,
  });

  final ChatMessage message;
  final bool streaming;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.content.isEmpty)
            const _ThinkingIndicator()
          else
            _StreamingText(
              text: message.content,
              streaming: streaming,
              stopped: message.stoppedByUser,
            ),
          if (showActions && !streaming && message.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  ReplyCopyButton(text: message.content),
                  if (message.stoppedByUser)
                    Text(
                      context.strings.stopped,
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelTertiary,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const TypingDots(),
        const SizedBox(width: 8),
        Text(
          context.strings.thinking,
          style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
        ),
      ],
    );
  }
}

/// 三点脉冲（3 个 4×4 fill3 圆点依次缩放，周期 900ms，规范 §4.8）。
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = .5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value - i * 0.2) % 1.0;
            final scale =
                0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            return Container(
              margin: const EdgeInsets.only(right: 4),
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: c.fill3, shape: BoxShape.circle),
              transform: Matrix4.diagonal3Values(scale, scale, 1),
              transformAlignment: Alignment.center,
            );
          }),
        );
      },
    );
  }
}

class _StreamingText extends StatefulWidget {
  const _StreamingText({
    required this.text,
    required this.streaming,
    required this.stopped,
  });

  final String text;
  final bool streaming;
  final bool stopped;

  @override
  State<_StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<_StreamingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursor = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCursor();
  }

  @override
  void didUpdateWidget(_StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCursor();
  }

  void _syncCursor() {
    if (!widget.streaming || MediaQuery.disableAnimationsOf(context)) {
      _cursor.stop();
      _cursor.value = 1;
    } else if (!_cursor.isAnimating) {
      _cursor.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _cursor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = AppTextStyles.chatBody.copyWith(color: c.labelPrimary);
    final content = AiMarkdown(text: widget.text, baseStyle: style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.streaming ? content : SelectionArea(child: content),
        if (widget.streaming)
          AnimatedBuilder(
            animation: _cursor,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Opacity(
                opacity: .3 + .7 * _cursor.value,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.labelSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
