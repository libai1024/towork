import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/recurrence_commands.dart';
import 'package:towork/app/workspace_ui_commands.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/models/todo.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

void main() {
  late Directory dir;
  late AppDatabase db;
  late LocalWorkspaceSession session;
  late WorkspaceUiCommands ordinary;
  late RecurrenceCommands repeat;
  late String id;
  final now = DateTime.utc(2026, 9, 24);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('recurrence-proposals-');
    db = AppDatabase.background(File('${dir.path}/db.sqlite'));
    final store = SqliteWorkspaceCommandStore(db, clock: () => now);
    session = LocalWorkspaceSession(store, await store.load());
    ordinary = WorkspaceUiCommands(
      session.todos,
      session.categories,
      session: session,
    );
    repeat = RecurrenceCommands(session, clock: () => now);
    id = (await ordinary.createTodo(title: '系列待办', dueAt: now)).id;
  });
  tearDown(() async {
    await session.dispose();
    session.todos.dispose();
    session.categories.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });
  Todo todo() => session.todos.byId(id)!;
  Future<void> start() => repeat.execute(
    repeat
        .startProposal(todo(), 'FREQ=DAILY;COUNT=4', 'Asia/Shanghai')
        .choices
        .single
        .command,
  );

  test('start is review-only until submitted, and undo restores the independent task', () async {
    final proposal = repeat.startProposal(
      todo(),
      'FREQ=DAILY;COUNT=4',
      'Asia/Shanghai',
    );
    expect(session.snapshot.series, isEmpty);
    expect(session.todos.snapshot, hasLength(1));
    expect(proposal.choices.single.count(WorkspaceMutationKind.create), 3);
    final saved = await repeat.execute(proposal.choices.single.command);
    expect(session.todos.snapshot, hasLength(4));
    await saved.undo();
    expect(session.todos.snapshot, hasLength(1));
    expect(todo().repeatRule, isNull);
    expect(todo().seriesId, isNull);
  });

  test('choices preserve exact intent, current edits one record and future edits template', () async {
    await start();
    final p = repeat.editProposal(todo(), todo().copyWith(note: '新的备注'));
    expect(p.choices.map((c) => c.label), ['仅本次', '本次及以后']);
    expect(p.choices.first.changes, hasLength(1));
    expect(p.choices.first.changes.single.after!['note'], '新的备注');
    final saved = await repeat.execute(p.choices.first.command);
    expect(session.todos.snapshot.where((t) => t.note == '新的备注'), hasLength(1));
    await saved.undo();
    final next = repeat.editProposal(todo(), todo().copyWith(note: '所有后续备注'));
    await repeat.execute(next.choices.last.command);
    expect(session.todos.snapshot.every((t) => t.note == '所有后续备注'), isTrue);
  });

  test('changing a calendar offers future scope only, clearing detaches the current item', () async {
    await start();
    final p = repeat.editProposal(
      todo(),
      todo().copyWith(repeatRule: null, repeatTimezone: null),
    );
    expect(p.choices.map((c) => c.label), ['本次及以后']);
    await repeat.execute(p.choices.single.command);
    expect(session.todos.snapshot, hasLength(1));
    expect(todo().seriesId, isNull);
  });

  test('repeated root rule splits followed by current undo still permit future editing', () async {
    await start();
    await repeat.execute(
      repeat
          .editProposal(
            todo(),
            todo().copyWith(repeatRule: 'FREQ=MONTHLY;BYMONTHDAY=24;COUNT=4'),
          )
          .choices
          .single
          .command,
    );
    await repeat.execute(
      repeat
          .editProposal(todo(), todo().copyWith(repeatTimezone: 'Asia/Tokyo'))
          .choices
          .single
          .command,
    );
    final single = await repeat.execute(
      repeat
          .editProposal(todo(), todo().copyWith(title: '单次标题'))
          .choices
          .first
          .command,
    );
    await single.undo();
    final next = repeat.editProposal(todo(), todo().copyWith(title: '后续标题'));
    expect(next.choices.map((c) => c.label), ['仅本次', '本次及以后']);
    await repeat.execute(next.choices.last.command);
    expect(session.todos.snapshot.every((t) => t.title == '后续标题'), isTrue);
  });

  test(
    'stale displayed task and a changed prepared deletion are rejected',
    () async {
      await start();
      final before = todo();
      final pending = repeat.deleteProposal(before).choices.last.command;
      await ordinary.updateTodo(before.copyWith(note: '确认期间修改'));
      expect(
        () => repeat.editProposal(before, before.copyWith(title: '过期')),
        throwsA(isA<WorkspaceFailure>()),
      );
      await expectLater(
        repeat.execute(pending),
        throwsA(isA<WorkspaceFailure>()),
      );
      expect(session.todos.snapshot, hasLength(4));
      expect(todo().note, '确认期间修改');
    },
  );
}
