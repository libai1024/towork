/// A task proposed by the assistant; it is committed only after reply completion.
class TodoDraft {
  const TodoDraft({required this.title, this.dueAt, this.categoryId});
  final String title;
  final DateTime? dueAt;
  final String? categoryId;
}

class ChatReply {
  const ChatReply({required this.text, this.draft});
  final String text;
  final TodoDraft? draft;
}
