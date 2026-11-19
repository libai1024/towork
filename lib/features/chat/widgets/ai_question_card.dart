import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_inline_input.dart';
import '../../../domain/chat/chat_question.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class AiQuestionCard extends StatefulWidget {
  const AiQuestionCard({
    super.key,
    required this.question,
    required this.enabled,
    required this.answered,
    required this.onAnswer,
    this.answer,
  });
  final ChatQuestion question;
  final bool enabled, answered;
  final String? answer;
  final Future<bool> Function(String text) onAnswer;

  @override
  State<AiQuestionCard> createState() => _AiQuestionCardState();
}

class _AiQuestionCardState extends State<AiQuestionCard> {
  final _selected = <String>{};
  final _other = TextEditingController();
  bool _editing = false, _sending = false, _sent = false;
  bool _showAnsweredOptions = false;
  String? _error;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _submit(Iterable<String> selected) async {
    if (!widget.enabled || _sending || _sent) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    var accepted = false;
    try {
      accepted = await widget.onAnswer(
        widget.question.answerText(
          selected,
          other: _editing ? _other.text : '',
        ),
      );
    } catch (_) {
      // Keep the selected answer and draft available for retry.
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = accepted;
      _error = accepted ? null : '未发送，请重试';
    });
    if (accepted) FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final question = widget.question;
    final answered = widget.answered || _sent;
    final enabled = widget.enabled && !_sending && !answered;
    final selected = widget.answer == null
        ? _selected
        : question.selectedFrom(widget.answer);
    final hasAnswer =
        _selected.isNotEmpty || (_editing && _other.text.trim().isNotEmpty);
    final title = Semantics(
      header: true,
      child: Text(
        question.displayTitle,
        style: AppTextStyles.chatBody.copyWith(
          color: c.labelPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    return Column(
      key: const ValueKey('ai-question-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (answered)
          Semantics(
            expanded: _showAnsweredOptions,
            child: AppPressable(
              key: const ValueKey('question-answered-options'),
              compact: true,
              minSize: 36,
              onTap: () =>
                  setState(() => _showAnsweredOptions = !_showAnsweredOptions),
              child: Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 6),
                  Text(
                    widget.answer != null || _sent ? '已回答' : '已继续对话',
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                  Icon(
                    _showAnsweredOptions
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 14,
                    color: c.labelSecondary,
                  ),
                ],
              ),
            ),
          )
        else
          title,
        if (!answered || _showAnsweredOptions) ...[
          const SizedBox(height: 4),
          for (final (index, option) in question.options.indexed)
            _QuestionOption(
              index: index,
              text: option,
              multiple: question.multiple,
              selected: selected.contains(option),
              answered: answered,
              onTap: !enabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (!question.multiple) _selected.clear();
                        if (!_selected.add(option)) _selected.remove(option);
                      });
                      if (!question.multiple && !_editing) _submit([option]);
                    },
            ),
        ],
        if (!answered && _editing)
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.separator),
            ),
            child: TextField(
              key: const ValueKey('question-custom-answer'),
              controller: _other,
              autofocus: true,
              readOnly: !enabled,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
              decoration: appInlineInput(
                hintText: '补充你的回答',
                hintStyle: AppTextStyles.footnote.copyWith(
                  color: c.labelTertiary,
                ),
                padding: const EdgeInsets.symmetric(vertical: 5),
              ).copyWith(counterText: ''),
              onChanged: (_) => setState(() {}),
            ),
          ),
        if (!answered)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Tooltip(
                  message: _editing ? '收起补充回答' : '补充回答',
                  child: AppPressable(
                    onTap: enabled
                        ? () => setState(() => _editing = !_editing)
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Icon(
                            _editing
                                ? LucideIcons.chevronUp
                                : LucideIcons.ellipsis,
                            size: 16,
                            color: c.labelSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _editing ? '收起' : '其他回答',
                            style: AppTextStyles.footnote.copyWith(
                              color: c.labelSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (question.multiple || _editing) ...[
                Flexible(
                  child: AppPressable(
                    key: const ValueKey('question-submit'),
                    semanticLabel: '确认回答',
                    onTap: enabled && hasAnswer
                        ? () => _submit(
                            question.options.where(_selected.contains),
                          )
                        : null,
                    child: Center(
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: hasAnswer ? c.brand : c.fill2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Text(
                            _sending
                                ? '发送中'
                                : _selected.isEmpty
                                ? '发送'
                                : '发送 ${_selected.length} 项',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.footnote.copyWith(
                              fontWeight: FontWeight.w500,
                              color: hasAnswer ? c.onBrand : c.labelSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: c.overdueForeground),
            ),
          ),
      ],
    );
  }
}

class _QuestionOption extends StatelessWidget {
  const _QuestionOption({
    required this.index,
    required this.text,
    required this.multiple,
    required this.selected,
    required this.answered,
    required this.onTap,
  });
  final int index;
  final String text;
  final bool multiple, selected, answered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final markerWidth = multiple
        ? 22.0
        : math.max(22.0, MediaQuery.textScalerOf(context).scale(16));
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: !multiple,
      child: AppPressable(
        minSize: answered ? 36 : 44,
        compact: answered,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: markerWidth,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: multiple ? 17 : markerWidth,
                        minHeight: multiple ? 17 : markerWidth,
                      ),
                      alignment: Alignment.center,
                      width: multiple ? 17 : null,
                      decoration: BoxDecoration(
                        color: selected
                            ? c.brand
                            : multiple
                            ? null
                            : c.fill2,
                        borderRadius: BorderRadius.circular(
                          multiple ? 5 : markerWidth / 2,
                        ),
                        border: multiple
                            ? Border.all(
                                color: selected ? c.brand : c.labelTertiary,
                              )
                            : null,
                      ),
                      child: selected
                          ? Icon(LucideIcons.check, size: 13, color: c.onBrand)
                          : multiple
                          ? null
                          : Text(
                              String.fromCharCode(65 + index),
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: c.labelSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.body.copyWith(
                    color: c.labelPrimary,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
