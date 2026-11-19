import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/jobs/local_job.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../local/app_database.dart';

/// Durable jobs are local intentions. Only a current lease may publish business
/// effects; external OS/network side effects need their own reconciliation.
class LocalJobStore {
  LocalJobStore(
    this.db, {
    DateTime Function()? clock,
    double Function()? jitter,
  }) : clock = clock ?? DateTime.now,
       jitter = jitter ?? Random().nextDouble;
  final AppDatabase db;
  final DateTime Function() clock;
  final double Function() jitter;
  int get _now => clock().toUtc().millisecondsSinceEpoch;
  LocalJob _decode(Map<String, Object?> r) => LocalJob(
    id: r['id']! as String,
    uniqueKey: r['unique_key']! as String,
    type: r['type']! as String,
    payload: (jsonDecode(r['payload']! as String) as Map)
        .cast<String, Object?>(),
    status: JobStatus.values.byName(r['status']! as String),
    attempts: r['attempts']! as int,
    maxAttempts: r['max_attempts']! as int,
    epoch: r['lease_epoch']! as int,
    dueAt: DateTime.fromMillisecondsSinceEpoch(
      r['due_at']! as int,
      isUtc: true,
    ),
    nextAttemptAt: DateTime.fromMillisecondsSinceEpoch(
      r['next_attempt_at']! as int,
      isUtc: true,
    ),
    owner: r['lease_owner'] as String?,
    errorCode: r['error_code'] as String?,
    leaseExpiresAt: r['lease_expires_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            r['lease_expires_at']! as int,
            isUtc: true,
          ),
    outcome: r['outcome'] == null
        ? null
        : (jsonDecode(r['outcome']! as String) as Map).cast<String, Object?>(),
  );
  Future<LocalJob?> read(String id) async {
    final row = await db
        .customSelect(
          'SELECT * FROM local_job_rows WHERE id = ?',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    return row == null ? null : _decode(row.data);
  }

  Future<List<LocalJob>> list({required String type}) async => [
    for (final row
        in await db
            .customSelect(
              'SELECT * FROM local_job_rows WHERE type = ? ORDER BY unique_key',
              variables: [Variable(type)],
            )
            .get())
      _decode(row.data),
  ];

  Future<LocalJob> enqueue({
    required String key,
    required String type,
    required DateTime dueAt,
    required Map<String, Object?> payload,
    int maxAttempts = 5,
  }) async {
    if (key.isEmpty ||
        key.length > 512 ||
        type.isEmpty ||
        type.length > 80 ||
        maxAttempts < 1 ||
        maxAttempts > 10) {
      throw const JobFailure('invalid');
    }
    final json = canonicalWorkspaceJson(freezeWorkspaceJson(payload));
    if (utf8.encode(json).length > 65536) {
      throw const JobFailure('payload_limit');
    }
    final due = dueAt.toUtc().millisecondsSinceEpoch;
    final digest = sha256
        .convert(utf8.encode('$type/$due/$maxAttempts/$json'))
        .toString();
    // One atomic statement handles competing initial enqueues and invalidates
    // every previous lease when the desired payload changes or is re-enabled.
    await db.customUpdate(
      '''INSERT INTO local_job_rows
      (id, unique_key, type, payload, digest, status, due_at, next_attempt_at, attempts, max_attempts, lease_epoch)
      VALUES (?, ?, ?, ?, ?, 'scheduled', ?, ?, 0, ?, 0)
      ON CONFLICT(unique_key) DO UPDATE SET type=excluded.type, payload=excluded.payload,
      digest=excluded.digest, status='scheduled', due_at=excluded.due_at,
      next_attempt_at=excluded.next_attempt_at, attempts=0, max_attempts=excluded.max_attempts,
      lease_epoch=local_job_rows.lease_epoch+1, lease_owner=NULL, lease_expires_at=NULL, outcome=NULL, error_code=NULL
      WHERE local_job_rows.digest != excluded.digest OR local_job_rows.status='cancelled' ''',
      variables: [
        Variable(newWorkspaceId('job')),
        Variable(key),
        Variable(type),
        Variable(json),
        Variable(digest),
        Variable(due),
        Variable(due),
        Variable(maxAttempts),
      ],
      updates: {db.localJobRows},
    );
    return _decode(
      (await db
              .customSelect(
                'SELECT * FROM local_job_rows WHERE unique_key=?',
                variables: [Variable(key)],
              )
              .getSingle())
          .data,
    );
  }

  Future<LocalJob?> claim({
    required String owner,
    required String type,
    Duration lease = const Duration(seconds: 30),
  }) async {
    if (owner.isEmpty ||
        owner.length > 200 ||
        lease.inMilliseconds < 1000 ||
        lease > const Duration(minutes: 5)) {
      throw const JobFailure('invalid');
    }
    final now = _now;
    await db.customUpdate(
      "UPDATE local_job_rows SET status='failed', error_code='lease_exhausted', lease_owner=NULL, lease_expires_at=NULL WHERE type=? AND status='running' AND lease_expires_at<=? AND attempts>=max_attempts",
      variables: [Variable(type), Variable(now)],
      updates: {db.localJobRows},
    );
    // RETURNING avoids a select/update race between independent connections.
    final rows = await db
        .customSelect(
          '''UPDATE local_job_rows SET status='running',
      attempts=attempts+1, lease_epoch=lease_epoch+1, lease_owner=?, lease_expires_at=?, lease_started_at=?
      WHERE id=(SELECT id FROM local_job_rows WHERE type=? AND attempts<max_attempts AND
      ((status IN ('scheduled','retryWait') AND next_attempt_at<=?) OR (status='running' AND lease_expires_at<=?))
      ORDER BY next_attempt_at, id LIMIT 1) RETURNING *''',
          variables: [
            Variable(owner),
            Variable(now + lease.inMilliseconds),
            Variable(now),
            Variable(type),
            Variable(now),
            Variable(now),
          ],
        )
        .get();
    return rows.isEmpty ? null : _decode(rows.single.data);
  }

  Future<bool> isCurrent(LocalJob lease) async {
    final row = await read(lease.id);
    return row != null &&
        row.status == JobStatus.running &&
        row.owner == lease.owner &&
        row.epoch == lease.epoch &&
        row.leaseExpiresAt!.millisecondsSinceEpoch > _now;
  }

  Future<void> _require(LocalJob lease) async {
    if (!await isCurrent(lease)) throw const JobFailure('lease_lost');
  }

  /// The callback must contain only local writes on this same database. Their
  /// publication and the success marker are atomic and protected by the fence.
  Future<void> complete(
    LocalJob lease, {
    Map<String, Object?> outcome = const {},
    Future<void> Function()? publish,
  }) => db.transaction(() async {
    await _require(lease);
    await publish?.call();
    await _require(lease);
    await db.customUpdate(
      "UPDATE local_job_rows SET status='succeeded', outcome=?, error_code=NULL, lease_owner=NULL, lease_expires_at=NULL WHERE id=?",
      variables: [
        Variable(canonicalWorkspaceJson(outcome)),
        Variable(lease.id),
      ],
      updates: {db.localJobRows},
    );
  });

  Future<void> fail(
    LocalJob lease, {
    required String code,
    bool retryable = true,
    JobStatus? waiting,
  }) => db.transaction(() async {
    await _require(lease);
    if (!RegExp(r'^[a-z_]{1,80}$').hasMatch(code) ||
        waiting != null &&
            !{
              JobStatus.waitingKey,
              JobStatus.waitingNetwork,
              JobStatus.waitingPermission,
            }.contains(waiting)) {
      throw const JobFailure('invalid');
    }
    final status =
        waiting ??
        (retryable && lease.attempts < lease.maxAttempts
            ? JobStatus.retryWait
            : JobStatus.failed);
    final delay = min(3600, 30 * pow(2, lease.attempts - 1)).toInt();
    await db.customUpdate(
      'UPDATE local_job_rows SET status=?, error_code=?, next_attempt_at=?, lease_owner=NULL, lease_expires_at=NULL WHERE id=?',
      variables: [
        Variable(status.name),
        Variable(code),
        Variable(
          _now + (delay * 1000 * (1 + jitter().clamp(0, 1) * .25)).round(),
        ),
        Variable(lease.id),
      ],
      updates: {db.localJobRows},
    );
  });

  Future<void> cancel(String id) => db
      .customUpdate(
        "UPDATE local_job_rows SET status='cancelled', lease_epoch=lease_epoch+1, lease_owner=NULL, lease_expires_at=NULL WHERE id=? AND status!='cancelled'",
        variables: [Variable(id)],
        updates: {db.localJobRows},
      )
      .then((_) {});

  Future<void> cancelLease(LocalJob lease) => db
      .customUpdate(
        "UPDATE local_job_rows SET status='cancelled', lease_epoch=lease_epoch+1, lease_owner=NULL, lease_expires_at=NULL WHERE id=? AND status='running' AND lease_owner=? AND lease_epoch=?",
        variables: [
          Variable(lease.id),
          Variable(lease.owner!),
          Variable(lease.epoch),
        ],
        updates: {db.localJobRows},
      )
      .then((_) {});

  Future<void> wake(String type, JobStatus state) async {
    if (!{
      JobStatus.waitingPermission,
      JobStatus.waitingKey,
      JobStatus.waitingNetwork,
      JobStatus.failed,
    }.contains(state)) {
      throw const JobFailure('invalid');
    }
    await db.customUpdate(
      "UPDATE local_job_rows SET status='scheduled', attempts=0, next_attempt_at=?, error_code=NULL WHERE type=? AND status=?",
      variables: [Variable(_now), Variable(type), Variable(state.name)],
      updates: {db.localJobRows},
    );
  }

  Future<void> renew(LocalJob lease, Duration duration) async {
    if (duration.inSeconds < 1 || duration > const Duration(minutes: 5)) {
      throw const JobFailure('invalid');
    }
    final count = await db.customUpdate(
      "UPDATE local_job_rows SET lease_expires_at=MIN(?,lease_started_at+300000) WHERE id=? AND status='running' AND lease_owner=? AND lease_epoch=? AND lease_expires_at>? AND lease_started_at+300000>?",
      variables: [
        Variable(_now + duration.inMilliseconds),
        Variable(lease.id),
        Variable(lease.owner!),
        Variable(lease.epoch),
        Variable(_now),
        Variable(_now),
      ],
      updates: {db.localJobRows},
    );
    if (count != 1) throw const JobFailure('lease_lost');
  }

  Future<int> allocateNotification(LocalJob lease) => db.transaction(() async {
    await _require(lease);
    await db
        .into(db.notificationAttempts)
        .insert(
          NotificationAttemptsCompanion.insert(
            jobId: lease.id,
            leaseEpoch: lease.epoch,
            payload: canonicalWorkspaceJson(lease.payload),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final row =
        await (db.select(db.notificationAttempts)..where(
              (r) =>
                  r.jobId.equals(lease.id) & r.leaseEpoch.equals(lease.epoch),
            ))
            .getSingle();
    if (row.id > 2147483647) throw const JobFailure('identity_limit');
    return row.id;
  });
}
