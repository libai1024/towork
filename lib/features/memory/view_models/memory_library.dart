import '../../../domain/models/memory.dart';

/// Immutable list projection keeps filtering/grouping independent of rendering.
class MemoryLibrary {
  MemoryLibrary({
    required List<MemoryEntry> entries,
    required this.kinds,
    required DateTime now,
    String selectedId = 'all',
    String query = '',
    MemorySource? source,
    MemoryExpiryFilter expiry = MemoryExpiryFilter.all,
  }) {
    final keyword = query.trim().toLowerCase();
    scoped = List.unmodifiable(
      entries.where((entry) {
        if (source != null && entry.source != source) return false;
        if (expiry == MemoryExpiryFilter.valid && entry.isExpired(now)) {
          return false;
        }
        if (expiry == MemoryExpiryFilter.expired && !entry.isExpired(now)) {
          return false;
        }
        return keyword.isEmpty || entry.content.toLowerCase().contains(keyword);
      }),
    );
    counts = Map.unmodifiable({
      'all': scoped.length,
      for (final kind in kinds)
        kind.id: scoped.where((entry) => kindId(entry) == kind.id).length,
    });
    visible = List.unmodifiable(
      scoped.where(
        (entry) => selectedId == 'all' || kindId(entry) == selectedId,
      ),
    );
    groups = List.unmodifiable([
      for (final kind in kinds)
        if (visible.any((entry) => kindId(entry) == kind.id))
          MemoryGroup(
            kind,
            visible.where((entry) => kindId(entry) == kind.id).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
          ),
    ]);
  }

  final List<MemoryKind> kinds;
  late final List<MemoryEntry> scoped;
  late final List<MemoryEntry> visible;
  late final Map<String, int> counts;
  late final List<MemoryGroup> groups;

  /// Imported entries whose custom directory is absent remain visible.
  String kindId(MemoryEntry entry) =>
      kinds.any((kind) => kind.id == entry.typeScopeId)
      ? entry.typeScopeId
      : entry.type.name;
}

class MemoryGroup {
  MemoryGroup(this.kind, List<MemoryEntry> entries)
    : entries = List.unmodifiable(entries);
  final MemoryKind kind;
  final List<MemoryEntry> entries;
}
