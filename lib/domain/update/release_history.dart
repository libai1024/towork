class ReleaseHistoryEntry {
  const ReleaseHistoryEntry({
    required this.build,
    required this.patch,
    required this.version,
    required this.date,
    required this.title,
    required this.notes,
  });
  final int build, patch;
  final String version, date, title;
  final List<String> notes;
  String get label => patch == 0 ? version : '$version P$patch';
  String get id => '$build/$patch';

  static List<ReleaseHistoryEntry> parse(Object? json) {
    if (json is! List || json.length > 5000) throw const FormatException();
    final entries = <ReleaseHistoryEntry>[];
    final ids = <String>{};
    for (final row in json) {
      if (row
          case {
            'build': final int build,
            'patch': final int patch,
            'version': final String version,
            'title': final String title,
            'date': final String date,
            'notes': final List<dynamic> notes,
          }
          when build > 0 &&
              patch >= 0 &&
              version.isNotEmpty &&
              title.isNotEmpty &&
              notes.isNotEmpty &&
              notes.every((n) => n is String && n.isNotEmpty)) {
        final entry = ReleaseHistoryEntry(
          build: build,
          patch: patch,
          version: version,
          date: date,
          title: title,
          notes: List.unmodifiable(notes.cast<String>()),
        );
        if (!ids.add(entry.id)) throw const FormatException();
        entries.add(entry);
      } else {
        throw const FormatException();
      }
    }
    entries.sort(
      (a, b) => a.build != b.build
          ? b.build.compareTo(a.build)
          : b.patch.compareTo(a.patch),
    );
    return entries;
  }
}
