enum RepositoryErrorCode { invalidInput, notFound, conflict }

/// A rejected repository command leaves the existing snapshot unchanged.
class RepositoryException implements Exception {
  const RepositoryException(this.code, this.message);
  final RepositoryErrorCode code;
  final String message;
  @override
  String toString() => message;
}
