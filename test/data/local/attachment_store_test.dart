import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:towork/data/local/attachment_store.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/platform/local_image_adapter.dart';
import 'package:towork/domain/attachments/local_image.dart';
import 'package:towork/domain/ai/model_gateway.dart';

import '../../support/free/business_agent_fixture.dart';
import '../../support/free/image_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late AppDatabase db;
  late AttachmentStore store;
  late Uint8List png;
  Future<void> connect() async {
    db = AppDatabase.background(File('${dir.path}/test.sqlite'));
    store = AttachmentStore(
      db,
      Directory('${dir.path}/attachments'),
      FlutterImagePreparer(),
    );
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('attachment-store');
    await connect();
    await SqliteWorkspaceCommandStore(db).execute(businessAgentFixture());
    png = await syntheticImage();
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  test('private originals survive restart; transport contains normalized copy, never paths in journal', () async {
    final original = Uint8List.fromList([
      ...png,
      ...utf8.encode('source-metadata-fixture'),
    ]);
    final row = await store.import(
      SelectedImage('../../票据.png', original),
      'ledger',
    );
    expect(row.displayName, '票据.png');
    expect(row.state, 'ready');
    expect(await store.bytes(row.id, original: true), original);
    expect(await store.bytes(row.id), isNot(original));
    final turn = await ChatPersistence(db).prepare(
      inputId: row.inputId,
      content: '识别图片',
      profile: ModelProfile(model: 'fixture'),
      agentEnabled: true,
      attachmentId: row.id,
    );
    expect(jsonEncode(turn.run.toJson()), isNot(contains('base64')));
    expect(jsonEncode(turn.run.toJson()), isNot(contains(dir.path)));
    await db.close();
    await connect();
    await store.recover();
    expect(await store.bytes(row.id, original: true), original);
    expect(
      (await ChatPersistence(db).load()).turns.single.inputId,
      row.inputId,
    );
    await expectLater(
      store.removeDraft(row.id),
      throwsA(
        isA<AttachmentFailure>().having(
          (e) => e.code,
          'code',
          AttachmentFailureCode.inUse,
        ),
      ),
    );
  });
  test('every file/database interruption recovers or exposes failed image without ready dangling references', () async {
    for (final point in AttachmentCheckpoint.values) {
      final broken = AttachmentStore(
        db,
        store.root,
        FlutterImagePreparer(),
        checkpoint: (at) {
          if (at == point) throw StateError('fault');
        },
      );
      await expectLater(
        broken.import(SelectedImage(point.name, png), 'ledger'),
        throwsA(isA<AttachmentFailure>()),
      );
      await store.recover();
      final row = (await store.forTable('ledger')).single;
      final complete = {
        AttachmentCheckpoint.copiesWritten,
        AttachmentCheckpoint.renamed,
        AttachmentCheckpoint.ready,
      }.contains(point);
      expect(row.state, complete ? 'ready' : 'failed');
      if (complete) {
        expect(await store.bytes(row.id, original: true), png);
      } else {
        await expectLater(
          store.bytes(row.id),
          throwsA(isA<AttachmentFailure>()),
        );
      }
      await store.removeDraft(row.id);
      expect(await store.forTable('ledger'), isEmpty);
      expect(
        (await store.root.list().toList()).where(
          (f) => !f.path.endsWith('/.lock'),
        ),
        isEmpty,
      );
    }
  });
  test('decode rejects corrupt, unsupported and oversized bytes; scales a real large image', () async {
    for (final bytes in [
      Uint8List.fromList([1, 2, 3]),
      png.sublist(0, 25),
      Uint8List(10 * 1024 * 1024 + 1),
    ]) {
      await expectLater(
        store.import(SelectedImage('fake.jpg', bytes), 'ledger'),
        throwsA(isA<AttachmentFailure>()),
      );
    }
    expect(await store.forTable('ledger'), isEmpty);
    final large = await syntheticImage(width: 2400, height: 1800);
    final prepared = await FlutterImagePreparer().prepare(large);
    expect(prepared.width, 2400);
    expect(prepared.height, 1800);
    final normalized = await FlutterImagePreparer().prepare(prepared.modelPng);
    expect(normalized.width, 1600);
    expect(normalized.height, 1200);
  });
  test('tampered and symlink files cannot be read; referenced originals are not removed', () async {
    final row = await store.import(SelectedImage('source.png', png), 'ledger');
    final outside = File('${dir.path}/outside.txt')
      ..writeAsStringSync('preserve');
    final copy = File('${store.root.path}/${row.id}.model.png');
    await copy.delete();
    await Link(copy.path).create(outside.path);
    await expectLater(store.bytes(row.id), throwsA(isA<AttachmentFailure>()));
    await expectLater(store.bytes('../outside'), throwsA(anything));
    await store.removeDraft(row.id);
    expect(outside.readAsStringSync(), 'preserve');
    final next = await store.import(SelectedImage('next.png', png), 'ledger');
    await File('${store.root.path}/${next.id}.original.png')
        .writeAsBytes(List.filled(next.originalSize, 0));
    await expectLater(
      store.bytes(next.id, original: true),
      throwsA(isA<AttachmentFailure>()),
    );
  });
  test('concurrent store instances serialize import and recovery; abandoned temp is reclaimed', () async {
    final second = AttachmentStore(db, store.root, FlutterImagePreparer());
    final result = await Future.wait([
      store.import(SelectedImage('one.png', png), 'ledger'),
      second.import(SelectedImage('two.png', png), 'ledger'),
    ]);
    await Future.wait([store.recover(), second.recover()]);
    expect(
      (await store.forTable('ledger')).map((r) => r.state),
      everyElement('ready'),
    );
    final orphan = File('${store.root.path}/image_deadbeef.model.png.tmp');
    await orphan.writeAsBytes(png);
    await store.recover();
    expect(await orphan.exists(), isFalse);
    for (final r in result) {
      expect(await store.bytes(r.id, original: true), png);
    }
  });
  test('chat attachments skip table binding, prepare without a table and keep the full tool list', () async {
    final row = await store.importForChat(SelectedImage('截图.png', png));
    expect(row.tableId, '');
    expect(row.state, 'ready');
    expect(await store.bytes(row.id), isNotEmpty);

    final turn = await ChatPersistence(db).prepare(
      inputId: row.inputId,
      content: '图片「截图.png」：看看这是什么',
      profile: ModelProfile(model: 'fixture'),
      agentEnabled: true,
      attachmentId: row.id,
    );
    expect(turn.inputId, row.inputId);
    expect(jsonEncode(turn.run.toJson()), contains('_towork_attachment_id'));

    JsonObject tool(String name) => {
      'type': 'function',
      'function': {
        'name': name,
        'parameters': {
          'type': 'object',
          'properties': <String, Object?>{},
          'required': <String>[],
        },
      },
    };
    ModelRequest request(String attachmentId) => ModelRequest(
      profile: ModelProfile(model: 'fixture'),
      messages: [
        {'role': 'system', 'content': 's'},
        {
          'role': 'user',
          'content': '看看',
          '_towork_attachment_id': attachmentId,
        },
      ],
      tools: [tool('todo_create'), tool('data_row_list')],
    );

    // 对话直传：图片进传输层，工具清单完整保留。
    final chat = await store.hydrate(request(row.id));
    expect(chat.tools, hasLength(2), reason: '对话直传不裁剪工具');
    final chatContent = chat.messages[1]['content'];
    expect(
      chatContent,
      isA<List<Object?>>().having((l) => l.length, 'parts', 2),
    );

    // 对照：截图导入（表附件）仍收敛到目标表的工具。
    final tableRow = await store.import(SelectedImage('票据.png', png), 'ledger');
    final scoped = await store.hydrate(request(tableRow.id));
    expect(scoped.tools, hasLength(1));
    final scopedParams =
        ((scoped.tools.single['function']! as Map)['parameters']!
                as Map)['properties']!
            as Map<Object?, Object?>;
    final tableIdEnum = (scopedParams['table_id']! as Map)['enum'];
    expect(tableIdEnum, [tableRow.tableId]);
  });
  test(
    'chat imports are independent of tables and removable before use',
    () async {
      final a = await store.importForChat(SelectedImage('a.png', png));
      final b = await store.importForChat(SelectedImage('b.png', png));
      expect(a.tableId, isEmpty);
      expect(b.tableId, isEmpty);
      expect(a.id, isNot(b.id), reason: '重复内容也各自成行，不做去重合并');
      expect(await store.forTable(''), hasLength(2));
      // 未发送的草稿附件可删除，且不残留文件。
      await store.removeDraft(a.id);
      expect(await store.forTable(''), hasLength(1));
      final names = (await store.root.list().toList())
          .map((f) => f.path.split('/').last)
          .toSet();
      expect(
        names.where((n) => n.startsWith(a.id)),
        isEmpty,
        reason: '被删附件不残留文件',
      );
      expect(names.where((n) => n.startsWith(b.id)), hasLength(2));
    },
  );
  test('chat import rejects oversized bytes without leaving rows', () async {
    final huge = Uint8List(10 * 1024 * 1024 + 1);
    await expectLater(
      store.importForChat(SelectedImage('huge.png', huge)),
      throwsA(
        isA<AttachmentFailure>().having(
          (e) => e.code,
          'code',
          AttachmentFailureCode.tooLarge,
        ),
      ),
    );
    expect(await store.forTable(''), isEmpty);
  });
  test('chat import rejects truncated pixel payloads', () async {
    await expectLater(
      store.importForChat(SelectedImage('cut.png', png.sublist(0, 64))),
      throwsA(isA<AttachmentFailure>()),
    );
    expect(await store.forTable(''), isEmpty);
  });
  test('concurrent store instances serialize chat imports', () async {
    final second = AttachmentStore(db, store.root, FlutterImagePreparer());
    final rows = await Future.wait([
      store.importForChat(SelectedImage('one.png', png)),
      second.importForChat(SelectedImage('two.png', png)),
    ]);
    await Future.wait([store.recover(), second.recover()]);
    expect(
      (await store.forTable('')).map((r) => r.state),
      everyElement('ready'),
    );
    for (final row in rows) {
      expect(await store.bytes(row.id), isNotEmpty);
    }
  });
  test('v9 upgrade preserves business history; foreign attachment table rolls upgrade back', () async {
    await db.close();
    final migrationFile = File('${dir.path}/migration.sqlite');
    var raw = sqlite.sqlite3.open(migrationFile.path);
    raw.execute(File('test/fixtures/local/schema_v9.sql').readAsStringSync());
    raw.execute(
      "INSERT INTO local_profiles VALUES(1,'old-user','保留姓名',1,1700000000)",
    );
    raw.execute('CREATE TABLE local_attachments(alien TEXT)');
    raw.close();
    db = AppDatabase.background(migrationFile);
    await expectLater(db.select(db.localAttachments).get(), throwsA(anything));
    await db.close();
    raw = sqlite.sqlite3.open(migrationFile.path);
    expect(raw.select('PRAGMA user_version').single['user_version'], 9);
    expect(
      raw.select('SELECT nickname FROM local_profiles').single['nickname'],
      '保留姓名',
    );
    raw.execute('DROP TABLE local_attachments');
    raw.close();
    db = AppDatabase.background(migrationFile);
    expect(await db.select(db.localAttachments).get(), isEmpty);
    expect((await db.loadOrCreateProfile()).nickname, '保留姓名');
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      13,
    );
  });
  test('one un-recoverable row does not block the rest of recover()', () async {
    final stuck = await store.import(SelectedImage('占用.png', png), 'ledger');
    final pending = await store.import(SelectedImage('待恢复.png', png), 'ledger');
    // stuck：删除被输入引用打断（仍存在 chat_turn）→ 恢复时应抛 inUse。
    await ChatPersistence(db).prepare(
      inputId: stuck.inputId,
      content: '识别图片',
      profile: ModelProfile(model: 'fixture'),
      agentEnabled: true,
      attachmentId: stuck.id,
    );
    await (db.update(db.localAttachments)..where((r) => r.id.equals(stuck.id)))
        .write(const LocalAttachmentsCompanion(state: Value('deleting')));
    // pending：rename 完成前被打断（文件齐备，状态仍 staging）。
    await (db.update(db.localAttachments)
          ..where((r) => r.id.equals(pending.id)))
        .write(const LocalAttachmentsCompanion(state: Value('staging')));
    await store.recover(); // 修复前：整表恢复被 inUse 打断并抛出。
    final states = {
      for (final row in await db.select(db.localAttachments).get())
        row.id: row.state,
    };
    expect(states[stuck.id], 'deleting', reason: '被引用行保持墓碑，不误删');
    expect(states[pending.id], 'ready', reason: '其余行照常恢复');
    expect(await store.bytes(pending.id), isNotEmpty);
  });
}
