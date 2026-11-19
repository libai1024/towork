import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/attachments/local_image.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../domain/workspace/workspace_validation.dart';
import 'app_database.dart';

enum AttachmentCheckpoint {
  registered,
  originalWritten,
  copiesWritten,
  renamed,
  ready,
}

/// SQLite journals the file lifecycle. A process-wide queue and OS file lock
/// serialize recovery, imports and deletion for one private directory.
class AttachmentStore {
  AttachmentStore(this.db, this.root, this.preparer, {this.checkpoint});
  final AppDatabase db;
  final Directory root;
  final ImagePreparer preparer;
  final void Function(AttachmentCheckpoint)? checkpoint;
  static final _queues = <String, Future<void>>{};

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    final key = root.absolute.path;
    final previous = _queues[key] ?? Future<void>.value();
    final done = Completer<void>();
    _queues[key] = done.future;
    await previous;
    RandomAccessFile? lock;
    try {
      if (await FileSystemEntity.type(root.path, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const AttachmentFailure(AttachmentFailureCode.storage);
      }
      await root.create(recursive: true);
      final lockFile = File('${root.path}/.lock');
      if (await FileSystemEntity.type(lockFile.path, followLinks: false) ==
          FileSystemEntityType.link) {
        throw const AttachmentFailure(AttachmentFailureCode.storage);
      }
      lock = await lockFile.open(mode: FileMode.append);
      await lock.lock(FileLock.blockingExclusive);
      return await action();
    } on AttachmentFailure {
      rethrow;
    } on WorkspaceFailure {
      rethrow;
    } catch (_) {
      throw const AttachmentFailure(AttachmentFailureCode.storage);
    } finally {
      try {
        await lock?.close();
      } finally {
        done.complete();
        if (identical(_queues[key], done.future)) _queues.remove(key);
      }
    }
  }

  File _file(String id, String suffix) {
    validateWorkspaceId(id);
    return File('${root.path}/$id.$suffix');
  }

  String _original(ImageAttachment row) =>
      row.mime == 'image/png' ? 'original.png' : 'original.jpg';
  Future<ImageAttachment> read(String id) async {
    validateWorkspaceId(id);
    final row = await (db.select(
      db.localAttachments,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw const AttachmentFailure(AttachmentFailureCode.missing);
    }
    return _info(row);
  }

  ImageAttachment _info(LocalAttachment row) => ImageAttachment(
    id: row.id,
    inputId: row.inputId,
    tableId: row.tableId,
    displayName: row.displayName,
    mime: row.mime,
    originalHash: row.originalHash,
    originalSize: row.originalSize,
    modelHash: row.modelHash,
    modelSize: row.modelSize,
    width: row.width,
    height: row.height,
    state: row.state,
    createdAt: row.createdAt,
  );
  Future<List<ImageAttachment>> forTable(String tableId) async => [
    for (final row
        in await (db.select(db.localAttachments)
              ..where((r) => r.tableId.equals(tableId))
              ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
            .get())
      _info(row),
  ];

  Future<ImageAttachment> import(SelectedImage selected, String tableId) async {
    validateWorkspaceId(tableId);
    return _register(selected, tableId, requireTable: true);
  }

  /// 对话直传图片：不属于任何业务表（tableId 存空串作标记）。
  /// prepare 跳过表存在性校验，hydrate 不做数据表工具裁剪。
  Future<ImageAttachment> importForChat(SelectedImage selected) =>
      _register(selected, '', requireTable: false);

  Future<ImageAttachment> _register(
    SelectedImage selected,
    String tableId, {
    required bool requireTable,
  }) async {
    final image = await preparer.prepare(selected.bytes);
    final id = newWorkspaceId('image');
    var name = selected.name
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '')
        .trim();
    name = String.fromCharCodes(name.runes.take(120));
    if (name.isEmpty) name = '图片';
    return _exclusive(() async {
      if (requireTable) {
        final table =
            await (db.select(db.workDataTables)
                  ..where((r) => r.id.equals(tableId) & r.deletedAt.isNull()))
                .getSingleOrNull();
        if (table == null) {
          throw const AttachmentFailure(AttachmentFailureCode.missing);
        }
      }
      await db
          .into(db.localAttachments)
          .insert(
            LocalAttachmentsCompanion.insert(
              id: id,
              inputId: newWorkspaceId('image_input'),
              tableId: tableId,
              displayName: name,
              mime: image.mime,
              originalHash: sha256.convert(image.original).toString(),
              originalSize: image.original.length,
              modelHash: sha256.convert(image.modelPng).toString(),
              modelSize: image.modelPng.length,
              width: image.width,
              height: image.height,
              state: 'staging',
              createdAt: DateTime.now().toUtc().microsecondsSinceEpoch,
            ),
          );
      checkpoint?.call(AttachmentCheckpoint.registered);
      final row = await read(id);
      await _file(
        id,
        '${_original(row)}.tmp',
      ).writeAsBytes(image.original, flush: true);
      checkpoint?.call(AttachmentCheckpoint.originalWritten);
      await _file(
        id,
        'model.png.tmp',
      ).writeAsBytes(image.modelPng, flush: true);
      checkpoint?.call(AttachmentCheckpoint.copiesWritten);
      await _finish(row);
      checkpoint?.call(AttachmentCheckpoint.ready);
      return read(id);
    });
  }

  Future<Uint8List?> _checkedFile(File file, String hash, int size) async {
    if (size < 1 ||
        size > 10 * 1024 * 1024 ||
        await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() != size) {
      return null;
    }
    final bytes = await file.readAsBytes();
    return bytes.length == size && sha256.convert(bytes).toString() == hash
        ? bytes
        : null;
  }

  Future<bool> _validFile(File file, String hash, int size) async =>
      await _checkedFile(file, hash, size) != null;

  Future<bool> _promote(String id, String suffix, String hash, int size) async {
    final finalFile = _file(id, suffix), temp = _file(id, '$suffix.tmp');
    if (await _validFile(finalFile, hash, size)) return true;
    if (!await _validFile(temp, hash, size)) return false;
    if (await FileSystemEntity.type(finalFile.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw const AttachmentFailure(AttachmentFailureCode.storage);
    }
    await temp.rename(finalFile.path);
    return true;
  }

  Future<void> _finish(ImageAttachment row) async {
    final original = await _promote(
      row.id,
      _original(row),
      row.originalHash,
      row.originalSize,
    );
    final model = await _promote(
      row.id,
      'model.png',
      row.modelHash,
      row.modelSize,
    );
    if (original && model) checkpoint?.call(AttachmentCheckpoint.renamed);
    await (db.update(
      db.localAttachments,
    )..where((r) => r.id.equals(row.id))).write(
      LocalAttachmentsCompanion(
        state: Value(original && model ? 'ready' : 'failed'),
      ),
    );
  }

  Future<void> recover() => _exclusive(() async {
    for (final record in await db.select(db.localAttachments).get()) {
      final row = _info(record);
      // 单行恢复失败（仍被引用、文件校验不过等）只跳过该行，不能让
      // 其余附件的恢复整体失败——provider 会缓存首次失败并持续报错。
      try {
        if (row.state == 'staging') await _finish(row);
        if (row.state == 'deleting') await _deleteFilesAndRow(row);
      } on AttachmentFailure {
        // 行状态保持原样，等待下一次 recover 或用户手动删除。
      }
    }
    // Only known temporary names in this private directory are eligible; never
    // follow links or delete files outside it. Ready sources remain retained.
    final ids = (await db.select(db.localAttachments).get())
        .map((r) => r.id)
        .toSet();
    await for (final file in root.list(followLinks: false)) {
      final name = file.uri.pathSegments.last;
      if (file is File &&
          RegExp(r'^image_[a-f0-9]+\.(original\.(png|jpg)|model\.png)\.tmp$')
              .hasMatch(name) &&
          !ids.contains(name.split('.').first)) {
        await file.delete();
      }
    }
  });
  Future<Uint8List> bytes(String id, {bool original = false}) =>
      _exclusive(() async {
        final row = await read(id);
        if (row.state != 'ready') {
          throw const AttachmentFailure(AttachmentFailureCode.missing);
        }
        final file = _file(id, original ? _original(row) : 'model.png');
        final hash = original ? row.originalHash : row.modelHash;
        final size = original ? row.originalSize : row.modelSize;
        final bytes = await _checkedFile(file, hash, size);
        if (bytes == null ||
            !original &&
                !await _validFile(
                  _file(id, _original(row)),
                  row.originalHash,
                  row.originalSize,
                )) {
          throw const AttachmentFailure(AttachmentFailureCode.missing);
        }
        return bytes;
      });
  Future<bool> hasInput(ImageAttachment row) async =>
      await (db.select(
        db.chatTurns,
      )..where((r) => r.inputId.equals(row.inputId))).getSingleOrNull() !=
      null;
  Future<void> removeDraft(String id) => _exclusive(() async {
    final row = await read(id);
    // Both reference check and tombstone are transactional against prepare().
    await db.transaction(() async {
      if (await hasInput(row)) {
        throw const AttachmentFailure(AttachmentFailureCode.inUse);
      }
      await (db.update(db.localAttachments)..where((r) => r.id.equals(id)))
          .write(const LocalAttachmentsCompanion(state: Value('deleting')));
    });
    await _deleteFilesAndRow(row);
  });
  Future<void> _deleteFilesAndRow(ImageAttachment row) async {
    if (await hasInput(row)) {
      throw const AttachmentFailure(AttachmentFailureCode.inUse);
    }
    for (final suffix in [
      _original(row),
      'model.png',
      '${_original(row)}.tmp',
      'model.png.tmp',
    ]) {
      final f = _file(row.id, suffix);
      final type = await FileSystemEntity.type(f.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        await Link(f.path).delete();
      } else if (type == FileSystemEntityType.file) {
        await f.delete();
      }
    }
    await (db.delete(
      db.localAttachments,
    )..where((r) => r.id.equals(row.id))).go();
  }

  Future<List<ImageAttachment>> sourcesForRow(String rowId) async {
    validateWorkspaceId(rowId);
    final results = await db
        .customSelect(
          '''
      SELECT DISTINCT a.* FROM local_attachments a
      JOIN agent_run_rows r ON r.input_id = a.input_id
      JOIN json_each(r.payload, '\$.receipts') receipts
      JOIN workspace_operations o ON o.operation_id = receipts.value
      JOIN json_each(o.changes) changes
      WHERE json_extract(changes.value, '\$.after.kind') = 'dataRow'
        AND json_extract(changes.value, '\$.after.id') = ?
      ORDER BY a.created_at DESC
    ''',
          variables: [Variable<String>(rowId)],
        )
        .get();
    return [for (final row in results) await read(row.read<String>('id'))];
  }

  /// Attach bytes only at the transport boundary; history keeps local IDs.
  Future<ModelRequest> hydrate(ModelRequest request) async {
    final messages = <JsonObject>[];
    var count = 0;
    for (final message in request.messages) {
      final attachmentId = message['_towork_attachment_id'];
      if (attachmentId == null) {
        messages.add(message);
        continue;
      }
      if (message['role'] != 'user' || attachmentId is! String || ++count > 4) {
        throw const ModelFailure(ModelFailureCode.configuration);
      }
      final copy = {...message}..remove('_towork_attachment_id');
      final data = await bytes(attachmentId);
      copy['content'] = [
        {'type': 'text', 'text': message['content']},
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/png;base64,${base64Encode(data)}'},
        },
      ];
      messages.add(copy);
    }
    var tools = request.tools;
    final latestUser = request.messages.lastWhere((m) => m['role'] == 'user');
    if (latestUser['_towork_attachment_id'] case final String id) {
      final image = await read(id);
      // 对话直传（tableId 为空串）不裁剪工具；截图导入才收敛到目标表。
      if (image.tableId.isNotEmpty) {
        tools = [
          for (final tool in tools)
            if ({
              'data_table_get',
              'data_row_list',
              'data_row_get',
              'data_row_create',
              'data_row_update',
            }.contains((tool['function']! as Map)['name']))
              _scopeTool(tool, image.tableId),
        ];
      }
    }
    return ModelRequest(
      profile: request.profile,
      messages: messages,
      tools: tools,
      maxTokens: request.maxTokens,
    );
  }

  JsonObject _scopeTool(JsonObject tool, String tableId) {
    final function = tool['function']! as JsonObject;
    final params = function['parameters']! as JsonObject;
    final props = params['properties']! as JsonObject;
    return {
      'type': 'function',
      'function': {
        ...function,
        'parameters': {
          ...params,
          'properties': {
            ...props,
            'table_id': {
              'type': 'string',
              'enum': [tableId],
            },
          },
          'required': [
            ...params['required']! as List,
            if ({
              'data_row_create',
              'data_row_update',
            }.contains(function['name']))
              'uncertain_field_ids',
          ],
        },
      },
    };
  }
}
