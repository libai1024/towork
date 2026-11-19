import 'dart:convert';

import '../../domain/chat/local_chat.dart';
import 'app_database.dart';

/// Result cards share the durable receipts used by undo and replay.
Future<LocalChatSnapshot> withChatTodoResults(
  AppDatabase db,
  LocalChatSnapshot snapshot,
) async {
  final receiptIds = {for (final turn in snapshot.turns) ...turn.run.receipts};
  if (receiptIds.isEmpty) return snapshot;
  final operations = await (db.select(
    db.workspaceOperations,
  )..where((row) => row.operationId.isIn(receiptIds))).get();
  final changesByReceipt = <String, List<Map<Object?, Object?>>>{};
  for (final operation in operations) {
    try {
      changesByReceipt[operation.operationId] = (jsonDecode(
        operation.changes,
      ) as List).cast<Map<Object?, Object?>>().toList();
    } catch (_) {
      // Historical corrupt receipts must not prevent conversations loading.
    }
  }
  return LocalChatSnapshot(snapshot.conversations, [
    for (final turn in snapshot.turns) _withResults(turn, changesByReceipt),
  ]);
}

LocalChatTurn _withResults(
  LocalChatTurn turn,
  Map<String, List<Map<Object?, Object?>>> changesByReceipt,
) {
  final firstBefore = <String, Map<Object?, Object?>?>{};
  final lastAfter = <String, Map<Object?, Object?>?>{};
  if (turn.undoneAt == null) {
    for (final receipt in turn.run.receipts) {
      for (final change in changesByReceipt[receipt] ?? const []) {
        final before = change['before'];
        final after = change['after'];
        final entity = after ?? before;
        if (entity is! Map ||
            entity['kind'] != 'todo' ||
            entity['id'] is! String) {
          continue;
        }
        if (before != null && before is! Map ||
            after != null && after is! Map) {
          continue;
        }
        final id = entity['id'] as String;
        firstBefore.putIfAbsent(id, () => before as Map?);
        lastAfter[id] = after as Map?;
      }
    }
  }
  final created = <String>[];
  final completed = <String>[];
  for (final entry in lastAfter.entries) {
    final after = entry.value;
    if (after == null || after['deleted_at'] != null) continue;
    final before = firstBefore[entry.key];
    if (before == null) created.add(entry.key);
    final oldData = before?['data'];
    final newData = after['data'];
    if (newData is Map &&
        newData['status'] == 'done' &&
        !(oldData is Map && oldData['status'] == 'done')) {
      completed.add(entry.key);
    }
  }
  return LocalChatTurn(
    inputId: turn.inputId,
    sessionId: turn.sessionId,
    content: turn.content,
    position: turn.position,
    historyStart: turn.historyStart,
    createdAt: turn.createdAt,
    agentEnabled: turn.agentEnabled,
    run: turn.run,
    undoneAt: turn.undoneAt,
    createdTodoIds: List.unmodifiable(created),
    completedTodoIds: List.unmodifiable(completed),
  );
}
