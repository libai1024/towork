import '../../domain/models/models.dart';
import '../../domain/repositories/memory_store.dart';
import '../seeds/memory_seed.dart';
import 'repository_validation.dart';

class MemoryRepository extends MemoryStore {
  MemoryRepository({List<MemoryEntry>? initial, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(
        requireUniqueIds(
          initial ?? seedMemories((clock ?? DateTime.now)()),
          (MemoryEntry entry) => entry.id,
        ),
      );

  final DateTime Function() _clock;

  int _seq = 100;

  /// 手动新增：source = manual，confidence = 1.0（08-memory.md §8.4）。
  @override
  MemoryEntry addManual({
    required String content,
    required MemoryType type,
    String? customTypeId,
    DateTime? expiresAt,
  }) {
    final now = _clock();
    String id;
    do {
      id = 'mem_gen_${_seq++}';
    } while (state.any((entry) => entry.id == id));
    final entry = MemoryEntry(
      id: id,
      content: requireText(content, '记忆内容'),
      type: type,
      customTypeId: customTypeId == null
          ? null
          : requireText(customTypeId, '记忆类型'),
      source: MemorySource.manual,
      confidence: 1.0,
      expiresAt: expiresAt,
      createdAt: now,
      updatedAt: now,
    );
    state = [entry, ...state];
    return entry;
  }

  @override
  void updateEntry(MemoryEntry entry) {
    state = [
      for (final e in state)
        e.id == entry.id
            ? entry.copyWith(
                content: requireText(entry.content, '记忆内容'),
                updatedAt: _clock(),
              )
            : e,
    ];
  }

  /// 删除并返回（条目, 原下标），供 5 秒撤销恢复。
  @override
  (MemoryEntry, int)? removeById(String id) {
    final index = state.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final entry = state[index];
    state = state.where((e) => e.id != id).toList();
    return (entry, index);
  }

  @override
  void insertAt(int index, MemoryEntry entry) {
    if (state.any((e) => e.id == entry.id)) return;
    final list = [...state];
    list.insert(index.clamp(0, list.length), entry);
    state = list;
  }

  /// 一键清空：返回被清掉的条目数，不提供撤销。
  @override
  int clearAll() {
    final count = state.length;
    state = const [];
    return count;
  }
}
