import '../../domain/models/chat.dart';

/// Layout and footer content for one visible row. A reply ends at the next user
/// message or explicit run boundary, including older messages without run IDs.
class ChatMessageRowLayout {
  const ChatMessageRowLayout({
    required this.message,
    required this.showDate,
    required this.followsReply,
    required this.continuesReply,
    this.replyText,
    this.stopped = false,
  });

  final ChatMessage message;
  final bool showDate, followsReply, continuesReply;

  /// Non-null only on the last row of a reply. Copy includes every text segment.
  final String? replyText;
  final bool stopped;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<ChatMessageRowLayout> layoutChatMessages(
  List<ChatMessage> expanded, {
  bool Function(String todoId)? todoExists,
}) {
  final visible = <ChatMessage>[];
  for (final message in expanded) {
    if (message.type == ChatMessageType.dataWriteCard) continue;
    if (message.type == ChatMessageType.todoCard &&
        (message.todoId == null ||
            !(todoExists?.call(message.todoId!) ?? true))) {
      continue;
    }
    final previous = visible.lastOrNull;
    final question = message.question;
    if (question != null &&
        previous != null &&
        previous.type == ChatMessageType.text &&
        previous.role == ChatRole.assistant &&
        message.runId != null &&
        message.runId == previous.runId &&
        message.sessionId == previous.sessionId) {
      final context = question.leadingContext(previous.content);
      if (context.trim().isEmpty) {
        visible.removeLast();
      } else if (context != previous.content) {
        visible[visible.length - 1] = previous.copyWith(content: context);
      }
    }
    visible.add(message);
  }
  final rows = <ChatMessageRowLayout>[];
  for (var start = 0; start < visible.length;) {
    final first = visible[start];
    var end = start;
    var runId = first.runId;
    if (first.role == ChatRole.assistant) {
      while (end + 1 < visible.length) {
        final next = visible[end + 1];
        if (next.role != ChatRole.assistant ||
            next.sessionId != first.sessionId ||
            (runId != null && next.runId != null && next.runId != runId)) {
          break;
        }
        runId ??= next.runId;
        end++;
      }
    }
    final group = visible.sublist(start, end + 1);
    final text = group
        .where(
          (message) =>
              message.type == ChatMessageType.text ||
              message.type == ChatMessageType.question,
        )
        .map((message) => message.question?.displayTitle ?? message.content)
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n');
    final stopped = group.any((message) => message.stoppedByUser);
    for (var i = start; i <= end; i++) {
      final message = visible[i];
      rows.add(
        ChatMessageRowLayout(
          message: message,
          showDate:
              i == start &&
              (i == 0 ||
                  !_sameDay(visible[i - 1].createdAt, message.createdAt)),
          followsReply: i > start,
          continuesReply: i < end,
          replyText: i == end && first.role == ChatRole.assistant ? text : null,
          stopped: stopped,
        ),
      );
    }
    start = end + 1;
  }
  return rows;
}
