import '../models/models.dart';
import 'list_store.dart';

abstract class MemoryStore extends ListStore<MemoryEntry> {
  MemoryStore(super.initial);
  MemoryEntry addManual({
    required String content,
    required MemoryType type,
    String? customTypeId,
    DateTime? expiresAt,
  });
  void updateEntry(MemoryEntry entry);
  (MemoryEntry, int)? removeById(String id);
  void insertAt(int index, MemoryEntry entry);
  int clearAll();
}
