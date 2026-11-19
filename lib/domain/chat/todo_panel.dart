import 'tool_ui_result.dart';

/// A conversation-local selection of existing tasks. Membership is a snapshot,
/// while task content and completion are resolved from the live workspace.
class TodoPanel {
  TodoPanel({
    required this.title,
    required this.asOfLocal,
    required this.overview,
    required Iterable<TodoPanelSection> sections,
  }) : sections = List.unmodifiable(sections);

  final String title, asOfLocal;
  final bool overview;
  final List<TodoPanelSection> sections;

  Map<String, Object?> toJson() => {
    'version': 1,
    'type': overview ? 'todo_overview' : 'todo_list',
    'title': title,
    'as_of_local': asOfLocal,
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  static TodoPanel? decode(Object? value, {required bool overview}) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['type'] != (overview ? 'todo_overview' : 'todo_list')) {
      return null;
    }
    final title = value['title'];
    final at = value['as_of_local'];
    final raw = value['sections'];
    if (!_text(title, 60) ||
        at is! String ||
        at.length > 40 ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})$')
            .hasMatch(at) ||
        DateTime.tryParse(at) == null ||
        raw is! List ||
        raw.isEmpty ||
        raw.length > (overview ? 5 : 1)) {
      return null;
    }
    final sections = <TodoPanelSection>[];
    for (final item in raw) {
      final section = TodoPanelSection.decode(item);
      if (section == null) return null;
      sections.add(section);
    }
    return TodoPanel(
      title: title as String,
      asOfLocal: at,
      overview: overview,
      sections: sections,
    );
  }
}

class TodoPanelSection {
  static const maxItems = 200;

  TodoPanelSection({
    required this.title,
    required Iterable<String> todoIds,
    required this.matchedCount,
  }) : todoIds = List.unmodifiable(todoIds);

  final String title;
  final List<String> todoIds;
  final int matchedCount;

  Map<String, Object?> toJson() => {
    'title': title,
    'todo_ids': todoIds,
    'matched_count': matchedCount,
  };

  static TodoPanelSection? decode(Object? value) {
    if (value is! Map) return null;
    final title = value['title'];
    final ids = value['todo_ids'];
    final count = value['matched_count'];
    if (!_text(title, 60) ||
        ids is! List ||
        ids.length > maxItems ||
        ids.any((id) => !_text(id, 200)) ||
        ids.toSet().length != ids.length ||
        count is! int ||
        count < ids.length) {
      return null;
    }
    return TodoPanelSection(
      title: title as String,
      todoIds: ids.cast<String>(),
      matchedCount: count,
    );
  }
}

bool _text(Object? value, int limit) =>
    value is String &&
    value.trim().isNotEmpty &&
    value.runes.length <= limit &&
    !value.contains(RegExp(r'[\x00-\x1f]'));

/// Projects this turn's validated interactive todo displays.
Map<int, TodoPanel> todoPanelsFromHistory(
  List<Map<String, Object?>> history,
  int historyStart,
) => {
  for (final entry in toolUiResults(history, historyStart, {
    'show_todo_list',
    'show_todo_overview',
  }).entries)
    entry.key: ?TodoPanel.decode(
      entry.value.ui,
      overview: entry.value.name == 'show_todo_overview',
    ),
};
