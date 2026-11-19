import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/memory_type_repository.dart';
import '../domain/models/memory.dart';
import '../domain/repositories/memory_type_store.dart';

/// Composition root; catalogue survives navigation alongside the mock memory store.
final memoryTypesProvider =
    StateNotifierProvider<MemoryTypeStore, List<MemoryKind>>(
      (ref) => MemoryTypeRepository(),
    );
