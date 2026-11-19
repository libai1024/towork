import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'tool_ui_result.dart';

/// A persisted clarification. Selecting an answer creates a normal user turn.
class ChatQuestion {
  ChatQuestion({
    required this.question,
    required Iterable<String> options,
    this.multiple = false,
  }) : options = List.unmodifiable(options);

  final String question;
  final List<String> options;
  final bool multiple;

  /// Older replies sometimes appended navigation instructions to the question.
  /// Keep the original prompt for stored answers and model history.
  String get displayTitle {
    final end = question.lastIndexOf(RegExp('[？?]'));
    if (end < 0 || end == question.length - 1) return question;
    final suffix = question.substring(end + 1).trim();
    final pickerHint = RegExp(
      r'^(?:[你您]可以|可以)(?:在选项[里中]|从选项中|直接)?选(?:择一项|择|一项)?'
      r'[，,](?:也|还)可以(?:直接)?补充(?:回答|说明(?:是哪件事)?)?[。！.!]?$',
    );
    return pickerHint.hasMatch(suffix)
        ? question.substring(0, end + 1)
        : question;
  }

  /// Keep the factual lead-in when the card already asks the final question.
  String leadingContext(String text) {
    final body = text.trimRight();
    for (final suffix in [question, displayTitle]) {
      if (body.endsWith(suffix)) {
        return body.substring(0, body.length - suffix.length).trimRight();
      }
    }
    return text.replaceFirst(
      RegExp(r'[，,]\s*(?:是想|需要|希望)让我(?:做什么|怎么做)[？?]\s*$'),
      '。',
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'type': 'question',
    'question': question,
    'options': options,
    'multiple': multiple,
  };

  static ChatQuestion? decode(Object? value) {
    if (value is! Map || value['version'] != 1 || value['type'] != 'question') {
      return null;
    }
    final question = value['question'];
    final options = value['options'];
    final multiple = value['multiple'];
    if (!_text(question, 200) ||
        options is! List ||
        options.length < 2 ||
        options.length > 6 ||
        options.any((option) => !_text(option, 60)) ||
        options.toSet().length != options.length ||
        multiple is! bool) {
      return null;
    }
    return ChatQuestion(
      question: question as String,
      options: options.cast<String>(),
      multiple: multiple,
    );
  }

  String answerText(Iterable<String> selected, {String other = ''}) => [
    question,
    ...selected.map((option) => '- $option'),
    if (other.trim().isNotEmpty) other.trim(),
  ].join('\n');

  Set<String> selectedFrom(String? answer) => {
    for (final option in options)
      if (answer?.split('\n').contains('- $option') ?? false) option,
  };

  static String answerInputId(String messageId) =>
      'answer_${sha256.convert(utf8.encode(messageId))}';
}

bool _text(Object? value, int limit) =>
    value is String &&
    value.trim().isNotEmpty &&
    value == value.trim() &&
    value.runes.length <= limit &&
    !value.contains(RegExp(r'[\x00-\x1f]'));

Map<int, ChatQuestion> questionsFromHistory(
  List<Map<String, Object?>> history,
  int historyStart,
) => {
  for (final entry in toolUiResults(history, historyStart, {
    'show_question',
  }).entries)
    entry.key: ?ChatQuestion.decode(entry.value.ui),
};
