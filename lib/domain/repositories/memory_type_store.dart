import '../models/memory.dart';
import 'list_store.dart';

/// Shared catalogue of built-in and user-created memory organization types.
abstract class MemoryTypeStore extends ListStore<MemoryKind> {
  MemoryTypeStore(super.initial);
  MemoryKind add(String label);
}
