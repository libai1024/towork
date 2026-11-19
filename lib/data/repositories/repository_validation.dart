import '../../domain/repositories/repository_error.dart';

List<T> requireUniqueIds<T>(Iterable<T> items, String Function(T) idOf) {
  final result = List<T>.of(items);
  final ids = <String>{};
  for (final item in result) {
    final id = idOf(item);
    if (id.isEmpty || !ids.add(id)) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '记录 ID 不能为空或重复',
      );
    }
  }
  return result;
}

String requireText(String text, String label) {
  final value = text.trim();
  if (value.isEmpty) {
    throw RepositoryException(RepositoryErrorCode.invalidInput, '$label不能为空');
  }
  return value;
}
