enum RepositoryErrorCode { invalidInput, notFound, conflict }

/// A rejected repository command leaves the existing snapshot unchanged.
class RepositoryException implements Exception {
  const RepositoryException(
    this.code,
    this.template, [
    this.arguments = const [],
  ]);
  final RepositoryErrorCode code;
  final String template;
  final List<String> arguments;
  String get message => arguments.isEmpty
      ? template
      : template.replaceAllMapped(
          RegExp(r'\{(\d+)\}'),
          (m) => arguments[int.parse(m[1]!)],
        );

  @override
  String toString() => message;
}
