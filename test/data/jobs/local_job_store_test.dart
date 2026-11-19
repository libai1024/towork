import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/data/jobs/local_job_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/jobs/local_job.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

void main() {
  late Directory dir;
  late File file;
  late AppDatabase db;
  late LocalJobStore jobs;
  late DateTime now;
  Future<LocalJob> enqueue({String title = 'one', int max = 5}) => jobs.enqueue(
    key: 'daily:2026-09-24',
    type: 'fixture',
    dueAt: DateTime.utc(2026, 9, 24),
    payload: {'title': title},
    maxAttempts: max,
  );
  Future<LocalJob> claim([String owner = 'worker']) async =>
      (await jobs.claim(owner: owner, type: 'fixture'))!;
  setUp(() async {
    now = DateTime.utc(2026, 9, 24);
    dir = await Directory.systemTemp.createTemp('towork-jobs');
    file = File('${dir.path}/db.sqlite');
    db = AppDatabase.background(file);
    jobs = LocalJobStore(db, clock: () => now, jitter: () => 0);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  test('idempotent enqueue, payload replacement and cancellation fence every old lease', () async {
    final initial = await enqueue();
    final lease = await claim();
    final replay = await enqueue();
    expect(replay.id, initial.id);
    expect(replay.epoch, lease.epoch);
    await enqueue(title: 'changed');
    await expectLater(jobs.complete(lease), throwsA(isA<JobFailure>()));
    final newer = await claim('second');
    await jobs.cancelLease(lease);
    expect(await jobs.isCurrent(newer), isTrue);
    await jobs.cancel(newer.id);
    await expectLater(jobs.complete(newer), throwsA(isA<JobFailure>()));
    expect((await enqueue(title: 'changed')).status, JobStatus.scheduled);
  });
  test(
    'independent connections claim once; expired old worker cannot publish',
    () async {
      await enqueue();
      final secondDb = AppDatabase.background(file);
      final second = LocalJobStore(secondDb, clock: () => now);
      try {
        final claimed = await Future.wait([
          jobs.claim(owner: 'a', type: 'fixture'),
          second.claim(owner: 'b', type: 'fixture'),
        ]);
        expect(claimed.whereType<LocalJob>(), hasLength(1));
        final old = claimed.whereType<LocalJob>().single;
        now = now.add(const Duration(seconds: 31));
        final newer = (await second.claim(owner: 'c', type: 'fixture'))!;
        var published = false;
        await expectLater(
          jobs.complete(
            old,
            publish: () async {
              published = true;
            },
          ),
          throwsA(isA<JobFailure>()),
        );
        expect(published, isFalse);
        expect(newer.epoch, greaterThan(old.epoch));
        await second.complete(newer, outcome: {'ok': true});
        expect((await jobs.read(newer.id))!.status, JobStatus.succeeded);
      } finally {
        await secondDb.close();
      }
    },
  );
  test('business publication and success marker roll back when lease expires during commit', () async {
    await enqueue();
    final lease = await claim();
    await expectLater(
      jobs.complete(
        lease,
        publish: () async {
          await SqliteWorkspaceCommandStore(db).execute(
            WorkspaceCommand(
              operationId: 'publish',
              actions: [
                WorkspaceMutation(
                  actionId: 'a',
                  kind: WorkspaceEntityKind.todo,
                  entityId: 't',
                  mutation: WorkspaceMutationKind.create,
                  patch: {'title': 'must rollback'},
                ),
              ],
            ),
          );
          now = now.add(const Duration(minutes: 1));
        },
      ),
      throwsA(isA<JobFailure>()),
    );
    expect((await SqliteWorkspaceCommandStore(db).load()).todos, isEmpty);
    expect((await jobs.read(lease.id))!.status, JobStatus.running);
  });
  test('finite retry, explicit wake, waiting conditions and reopen retain attempts', () async {
    await enqueue(max: 2);
    var lease = await claim();
    await jobs.fail(lease, code: 'network');
    expect(await jobs.claim(owner: 'early', type: 'fixture'), isNull);
    expect(
      (await jobs.read(lease.id))!.nextAttemptAt,
      now.add(const Duration(seconds: 30)),
    );
    now = now.add(const Duration(seconds: 30));
    lease = await claim();
    await jobs.fail(lease, code: 'network');
    expect((await jobs.read(lease.id))!.status, JobStatus.failed);
    await db.close();
    db = AppDatabase.background(file);
    jobs = LocalJobStore(db, clock: () => now);
    expect(await jobs.claim(owner: 'no-loop', type: 'fixture'), isNull);
    await jobs.wake('fixture', JobStatus.failed);
    lease = await claim();
    await jobs.fail(lease, code: 'missing_key', waiting: JobStatus.waitingKey);
    expect(await jobs.claim(owner: 'wait', type: 'fixture'), isNull);
    await jobs.wake('fixture', JobStatus.waitingKey);
    expect((await claim()).attempts, 1);
  });
  test('renewal cannot run beyond five minutes; exhausted crashes reach terminal failure', () async {
    await enqueue(max: 1);
    final lease = await claim();
    await jobs.renew(lease, const Duration(minutes: 5));
    now = now.add(const Duration(minutes: 4));
    await jobs.renew(lease, const Duration(minutes: 5));
    expect(
      (await jobs.read(lease.id))!.leaseExpiresAt,
      DateTime.utc(2026, 9, 24, 0, 5),
    );
    now = now.add(const Duration(minutes: 1));
    await expectLater(
      jobs.renew(lease, const Duration(seconds: 30)),
      throwsA(isA<JobFailure>()),
    );
    expect(await jobs.claim(owner: 'second', type: 'fixture'), isNull);
    expect((await jobs.read(lease.id))!.errorCode, 'lease_exhausted');
  });
  test(
    'notification identities are stable per lease and distinct across recovery',
    () async {
      await enqueue();
      final first = await claim();
      final one = await jobs.allocateNotification(first);
      expect(await jobs.allocateNotification(first), one);
      now = now.add(const Duration(seconds: 31));
      final second = await claim();
      expect(await jobs.allocateNotification(second), isNot(one));
      await expectLater(
        jobs.allocateNotification(first),
        throwsA(isA<JobFailure>()),
      );
    },
  );
  test('v7 migration preserves workspace and refuses foreign job tables atomically', () async {
    await db.close();
    var raw = sqlite.sqlite3.open(file.path);
    raw.execute(File('test/fixtures/local/schema_v7.sql').readAsStringSync());
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'v7-user','旧资料',2,1700000000)",
    );
    raw.execute('PRAGMA user_version=7');
    raw.execute('CREATE TABLE local_job_rows (alien TEXT)');
    raw.close();
    db = AppDatabase.background(file);
    await expectLater(
      db.customSelect('SELECT * FROM local_job_rows').get(),
      throwsA(anything),
    );
    await db.close();
    raw = sqlite.sqlite3.open(file.path);
    expect(raw.select('PRAGMA user_version').single['user_version'], 7);
    expect(
      raw.select(
        "SELECT name FROM sqlite_master WHERE name='notification_attempts'",
      ),
      isEmpty,
    );
    raw.execute('DROP TABLE local_job_rows');
    raw.close();
    db = AppDatabase.background(file);
    jobs = LocalJobStore(db, clock: () => now);
    await enqueue();
    expect((await db.loadOrCreateProfile()).nickname, '旧资料');
    expect((await jobs.list(type: 'fixture')), hasLength(1));
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      13,
    );
  });
}
