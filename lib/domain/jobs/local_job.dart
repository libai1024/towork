import '../workspace/workspace_commands.dart';

enum JobStatus {
  scheduled,
  running,
  succeeded,
  retryWait,
  failed,
  cancelled,
  waitingNetwork,
  waitingKey,
  waitingPermission,
}

class JobFailure implements Exception {
  const JobFailure(this.code);
  final String code;
  @override
  String toString() => 'JobFailure($code)';
}

class LocalJob {
  LocalJob({
    required this.id,
    required this.uniqueKey,
    required this.type,
    required Map<String, Object?> payload,
    required this.status,
    required this.attempts,
    required this.maxAttempts,
    required this.epoch,
    required this.dueAt,
    required this.nextAttemptAt,
    this.owner,
    this.leaseExpiresAt,
    this.errorCode,
    this.outcome,
  }) : payload = freezeWorkspaceJson(payload);
  final String id, uniqueKey, type;
  final Map<String, Object?> payload;
  final JobStatus status;
  final int attempts, maxAttempts, epoch;
  final DateTime dueAt, nextAttemptAt;
  final String? owner, errorCode;
  final DateTime? leaseExpiresAt;
  final Map<String, Object?>? outcome;
}
