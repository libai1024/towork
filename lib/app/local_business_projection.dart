import 'dart:async';
import 'dart:convert';

import '../data/local/business_model_codec.dart';
import '../data/local/app_database.dart';
import '../data/repositories/data_table_repository.dart';
import '../domain/models/data_table.dart';
import '../domain/repositories/data_table_bundle.dart';
import '../domain/repositories/repository_error.dart';
import '../domain/workspace/workspace_commands.dart';
import 'local_workspace_session.dart';

/// UI reads committed entities only; legacy synchronous mutation paths fail closed.
class LocalBusinessProjection extends DataTableRepository {
  LocalBusinessProjection(this.session, AppDatabase db)
    : super(initial: businessBundle(session.snapshot, historyLoading: true)) {
    _workspace = session.events.listen((_) => _refresh());
    _history = db
        .customSelect(
          'SELECT operation_id, source, changes, committed_at '
          'FROM workspace_operations ORDER BY rowid',
          readsFrom: {db.workspaceOperations},
        )
        .watch()
        .listen(
          (rows) {
            try {
              final tables = <String, DataTableDef>{};
              final logs = <DataChangeLog>[];
              for (final row in rows) {
                final changes = (jsonDecode(
                  row.read<String>('changes'),
                ) as List).cast<Map<String, Object?>>();
                for (final change in changes) {
                  final after = WorkspaceEntity.fromJson(
                    (change['after']! as Map).cast<String, Object?>(),
                  );
                  if (after.kind == WorkspaceEntityKind.dataTable) {
                    tables[after.id] = businessTable(after);
                  }
                }
                for (final change in changes) {
                  final after = WorkspaceEntity.fromJson(
                    (change['after']! as Map).cast<String, Object?>(),
                  );
                  if (after.kind != WorkspaceEntityKind.dataRow) continue;
                  final before = change['before'] == null
                      ? null
                      : WorkspaceEntity.fromJson(
                          (change['before']! as Map).cast<String, Object?>(),
                        );
                  final table = tables[after.data['table_id']];
                  if (table == null) {
                    throw const FormatException('Missing table history');
                  }
                  final values = after.data['values']! as Map<String, Object?>;
                  logs.add(
                    DataChangeLog(
                      id: '${row.read<String>('operation_id')}:${after.id}',
                      tableId: table.id,
                      rowId: after.id,
                      field: '',
                      oldValue: '',
                      newValue: '',
                      source: row.read<String>('source') == 'agent'
                          ? DataChangeSource.ai
                          : DataChangeSource.manual,
                      createdAt: DateTime.fromMicrosecondsSinceEpoch(
                        row.read<int>('committed_at'),
                      ).toLocal(),
                      action: after.isDeleted
                          ? DataChangeAction.delete
                          : before == null || before.isDeleted
                          ? DataChangeAction.create
                          : DataChangeAction.update,
                      beforeValues: before == null || before.isDeleted
                          ? null
                          : businessDisplayValues(
                              table,
                              before.data['values']! as Map<String, Object?>,
                            ),
                      afterValues: after.isDeleted
                          ? null
                          : businessDisplayValues(table, values),
                      persistedValues: after.isDeleted ? null : values,
                    ),
                  );
                }
              }
              if (!mounted) return;
              super.state = businessBundle(session.snapshot, logs: logs);
            } catch (_) {
              if (mounted) {
                super.state = state.copyWith(
                  historyLoading: false,
                  historyError: true,
                );
              }
            }
          },
          onError: (Object error) {
            if (mounted) {
              super.state = state.copyWith(
                historyLoading: false,
                historyError: true,
              );
            }
          },
        );
  }
  final LocalWorkspaceSession session;
  StreamSubscription<void>? _workspace;
  StreamSubscription<Object?>? _history;
  void _refresh() {
    if (mounted) {
      super.state = businessBundle(
        session.snapshot,
        logs: state.logs,
        historyLoading: state.historyLoading,
        historyError: state.historyError,
      );
    }
  }

  @override
  set state(DataTableBundle value) => throw const RepositoryException(
    RepositoryErrorCode.invalidInput,
    '请通过本地保存操作修改数据',
  );
  @override
  void dispose() {
    unawaited(_workspace?.cancel());
    unawaited(_history?.cancel());
    super.dispose();
  }
}
