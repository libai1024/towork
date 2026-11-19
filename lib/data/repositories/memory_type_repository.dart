import '../../domain/models/memory.dart';
import '../../domain/repositories/memory_type_store.dart';
import '../../domain/repositories/repository_error.dart';
import 'repository_validation.dart';

/// 当前 mock 阶段的类型目录，与记忆仓库采用相同的应用会话生命周期。
class MemoryTypeRepository extends MemoryTypeStore {
  MemoryTypeRepository({List<MemoryKind> customTypes = const []})
    : super(
        requireUniqueIds([...MemoryKind.builtIn, ...customTypes], (e) => e.id),
      );

  int _sequence = 1;

  @override
  MemoryKind add(String label) {
    final name = requireText(label, '类型名称');
    if (name.runes.length > 20) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '类型名称最多 20 个字',
      );
    }
    if (name == '全部' ||
        state.any((kind) => kind.label.toLowerCase() == name.toLowerCase())) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '该类型已存在',
      );
    }
    String id;
    do {
      id = 'memory_type_${_sequence++}';
    } while (state.any((kind) => kind.id == id));
    final kind = MemoryKind(id: id, label: name);
    state = [...state, kind];
    return kind;
  }
}
