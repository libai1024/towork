import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/repositories/memory_repository.dart';
import 'package:towork/data/repositories/memory_type_repository.dart';
import 'package:towork/domain/models/memory.dart';
import 'package:towork/domain/repositories/repository_error.dart';
import 'package:towork/features/memory/view_models/memory_library.dart';

void main() {
  final now = DateTime(2026, 9, 23);

  test('custom kinds are unique and cannot shadow built-in or all labels', () {
    final repo = MemoryTypeRepository();
    addTearDown(repo.dispose);
    final first = repo.add('  投资原则  ');
    final second = repo.add('研究笔记');
    expect(first.label, '投资原则');
    expect(first.id, isNot(second.id));
    expect(repo.snapshot, hasLength(6));
    for (final label in ['事实', '全部', '投资原则', ' ', 'a' * 21]) {
      expect(() => repo.add(label), throwsA(isA<RepositoryException>()));
    }
    expect(() => repo.snapshot.clear(), throwsUnsupportedError);
  });

  test(
    'custom assignment preserves semantic type and supports explicit clearing',
    () {
      final entries = MemoryRepository(initial: [], clock: () => now);
      addTearDown(entries.dispose);
      final entry = entries.addManual(
        content: '分散风险',
        type: MemoryType.preference,
        customTypeId: 'investment',
      );
      expect(entry.type, MemoryType.preference);
      expect(entry.typeScopeId, 'investment');
      expect(entry.copyWith(content: '控制仓位').customTypeId, 'investment');
      final changed = entry.copyWith(customTypeId: null);
      expect(changed.typeScopeId, 'preference');
      expect(entry.source, MemorySource.manual);
      entries.updateEntry(changed);
      final removed = entries.removeById(entry.id)!;
      entries.insertAt(removed.$2, removed.$1);
      expect(entries.snapshot.single.typeScopeId, 'preference');
    },
  );

  test('scope counts and groups include each entry exactly once', () {
    final types = MemoryTypeRepository();
    final entries = MemoryRepository(initial: [], clock: () => now);
    addTearDown(types.dispose);
    addTearDown(entries.dispose);
    final kind = types.add('投资原则');
    entries.addManual(
      content: '分散风险',
      type: MemoryType.preference,
      customTypeId: kind.id,
    );
    entries.addManual(content: '偏好简短回复', type: MemoryType.preference);
    final all = MemoryLibrary(
      entries: entries.snapshot,
      kinds: types.snapshot,
      now: now,
    );
    expect(all.counts, containsPair('all', 2));
    expect(all.counts['preference'], 1);
    expect(all.counts[kind.id], 1);
    final only = MemoryLibrary(
      entries: entries.snapshot,
      kinds: types.snapshot,
      now: now,
      selectedId: kind.id,
    );
    expect(only.visible.single.content, '分散风险');
    expect(only.groups.single.kind.id, kind.id);
    expect(all.groups.expand((group) => group.entries), hasLength(2));
  });

  test('missing imported custom kind falls back to original semantic type', () {
    final entry = MemoryEntry(
      id: 'import',
      content: '需要保留',
      type: MemoryType.event,
      customTypeId: 'missing',
      createdAt: now,
      updatedAt: now,
    );
    final library = MemoryLibrary(
      entries: [entry],
      kinds: MemoryKind.builtIn,
      now: now,
    );
    expect(library.groups.single.kind.id, 'event');
    expect(library.counts['event'], 1);
  });

  test('search, source and expiry filters apply before scope counts', () {
    final entries = MemoryRepository(initial: [], clock: () => now);
    addTearDown(entries.dispose);
    entries.addManual(content: '周三例会', type: MemoryType.event, expiresAt: now);
    entries.addManual(content: '周五例会', type: MemoryType.event);
    final library = MemoryLibrary(
      entries: entries.snapshot,
      kinds: MemoryKind.builtIn,
      now: now,
      query: '例会',
      source: MemorySource.manual,
      expiry: MemoryExpiryFilter.expired,
    );
    expect(library.visible.single.content, '周三例会');
    expect(library.counts['all'], 1);
    expect(library.counts['event'], 1);
  });
}
