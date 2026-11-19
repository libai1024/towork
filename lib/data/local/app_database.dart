import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../domain/ai/model_gateway.dart';
import '../../domain/settings/model_settings.dart';
import '../../domain/settings/local_profile.dart';

part 'app_database.g.dart';

class ProviderConfigurations extends Table {
  IntColumn get id => integer()();
  TextColumn get product => text()();
  TextColumn get region => text()();
  TextColumn get model => text()();
  BoolColumn get disableThinking => boolean()();
  IntColumn get version => integer()();
  TextColumn get credentialRef => text().nullable()();

  /// 当前配置来自哪个已保存账户；空表示尚未关联。
  TextColumn get accountId => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 已保存的模型账户。Key 只存引用；冷却与额度是可随时重建的观测数据。
@DataClassName('ProviderAccountRow')
class ProviderAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get product => text()();
  TextColumn get region => text()();
  TextColumn get model => text()();
  TextColumn get baseUrl => text().nullable()();
  BoolColumn get disableThinking => boolean()();
  TextColumn get credentialRef => text().nullable()();
  IntColumn get position => integer()();
  BoolColumn get autoRoute => boolean()();
  IntColumn get cooldownUntil => integer().nullable()();
  TextColumn get cooldownReason => text().nullable()();
  TextColumn get quotaPayload => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CredentialCleanup extends Table {
  TextColumn get reference => text()();
  @override
  Set<Column<Object>> get primaryKey => {reference};
}

@DataClassName('LocalProfileRow')
class LocalProfiles extends Table {
  IntColumn get singletonId => integer()();
  TextColumn get localUserId => text().unique()();
  TextColumn get nickname => text()();
  IntColumn get version => integer()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

@TableIndex.sql(
  'CREATE UNIQUE INDEX work_todos_occurrence_key ON work_todos (series_id, occurrence_key)',
)
@TableIndex.sql(
  'CREATE UNIQUE INDEX work_todos_occurrence_index ON work_todos (series_id, occurrence_index)',
)
@TableIndex(name: 'work_todos_category', columns: {#categoryId, #deletedAt})
@TableIndex(name: 'work_todos_due', columns: {#status, #dueAt, #deletedAt})
class WorkTodos extends Table {
  TextColumn get seriesId => text().nullable()();
  TextColumn get occurrenceKey => text().nullable()();
  IntColumn get occurrenceIndex => integer().nullable()();
  TextColumn get id => text()();
  IntColumn get version => integer()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get sortOrder => integer()();
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkTodoSeries extends Table {
  TextColumn get id => text()();
  IntColumn get version => integer()();
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'work_categories_parent', columns: {#parentId, #deletedAt})
class WorkCategories extends Table {
  TextColumn get id => text()();
  IntColumn get version => integer()();
  TextColumn get parentId => text().nullable()();
  BoolColumn get archived => boolean()();
  IntColumn get sortOrder => integer()();
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'work_data_tables_type', columns: {#typeId, #deletedAt})
class WorkDataTables extends Table {
  TextColumn get typeId => text().nullable()();
  BoolColumn get archived => boolean()();
  IntColumn get schemaRevision => integer()();
  TextColumn get id => text()();
  IntColumn get version => integer()();
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'work_data_rows_table', columns: {#tableId, #deletedAt})
class WorkDataRows extends Table {
  TextColumn get tableId => text()();
  TextColumn get id => text()();
  IntColumn get version => integer()();
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkTableTypes extends Table {
  TextColumn get id => text()();
  IntColumn get version => integer()();
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkspaceOperations extends Table {
  TextColumn get operationId => text()();
  TextColumn get requestDigest => text()();
  TextColumn get source => text()();
  TextColumn get undoOf => text().nullable()();
  TextColumn get receipt => text()();
  TextColumn get changes => text()();
  IntColumn get committedAt => integer()();
  @override
  Set<Column<Object>> get primaryKey => {operationId};
}

class AppPreferenceRows extends Table {
  IntColumn get singletonId => integer()();
  IntColumn get version => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}

class AgentRunRows extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get inputId => text()();
  IntColumn get revision => integer()();
  TextColumn get status => text()();
  TextColumn get initialRequest => text()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sessionId, inputId},
  ];
}

class AgentRunEvents extends Table {
  TextColumn get runId => text()();
  IntColumn get sequence => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {runId, sequence};
}

class ChatConversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get revision => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ChatTurns extends Table {
  TextColumn get inputId => text()();
  TextColumn get sessionId => text()();
  TextColumn get runId => text().unique()();
  TextColumn get content => text()();
  IntColumn get position => integer()();
  IntColumn get historyStart => integer()();
  IntColumn get createdAt => integer()();
  BoolColumn get agentEnabled => boolean()();
  IntColumn get undoneAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {inputId};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sessionId, position},
  ];
}

class LocalJobRows extends Table {
  TextColumn get id => text()();
  TextColumn get uniqueKey => text().unique()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  TextColumn get digest => text()();
  TextColumn get status => text()();
  IntColumn get dueAt => integer()();
  IntColumn get nextAttemptAt => integer()();
  IntColumn get attempts => integer()();
  IntColumn get maxAttempts => integer()();
  IntColumn get leaseEpoch => integer()();
  TextColumn get leaseOwner => text().nullable()();
  IntColumn get leaseExpiresAt => integer().nullable()();
  IntColumn get leaseStartedAt => integer().nullable()();
  TextColumn get outcome => text().nullable()();
  TextColumn get errorCode => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class NotificationAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jobId => text()();
  IntColumn get leaseEpoch => integer()();
  TextColumn get payload => text()();
  BoolColumn get cancelled => boolean().withDefault(const Constant(false))();
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {jobId, leaseEpoch},
  ];
}

/// Production schema begins with model settings; business tables follow through
/// explicit migrations. Probe databases are unrelated and are never imported.
/// Private image originals and normalized model copies; paths are derived from
/// IDs, never supplied by a model or a display filename.
class LocalAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get inputId => text().unique()();
  TextColumn get tableId => text()();
  TextColumn get displayName => text()();
  TextColumn get mime => text()();
  TextColumn get originalHash => text()();
  IntColumn get originalSize => integer()();
  TextColumn get modelHash => text()();
  IntColumn get modelSize => integer()();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  TextColumn get state => text()();
  IntColumn get createdAt => integer()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalMemories extends Table {
  TextColumn get id => text()();
  IntColumn get epoch => integer()();
  TextColumn get kindId => text()();
  TextColumn get content => text()();
  TextColumn get source => text()();
  TextColumn get sourceMessageId => text().nullable()();
  TextColumn get sourceSessionId => text().nullable()();
  TextColumn get sourceRecordId => text().nullable()();
  RealColumn get confidence => real()();
  IntColumn get expiresAt => integer().nullable()();
  IntColumn get version => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Immutable report snapshots (FC5): metrics and their exact denominators
/// are frozen at capture; summaries and renders reference, never rewrite.
class LocalReports extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  IntColumn get startAt => integer()();
  IntColumn get endAt => integer()();
  TextColumn get timezone => text()();
  TextColumn get snapshot => text()();
  TextColumn get status => text()();
  TextColumn get summary => text().nullable()();
  TextColumn get templateId => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single-row epoch/pause state; every delete, clear or pause advances the
/// epoch so late extraction tasks fail instead of reviving content.
class LocalMemoryState extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get epoch => integer()();
  BoolColumn get paused => boolean()();
  IntColumn get updatedAt => integer()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    ProviderConfigurations,
    ProviderAccounts,
    CredentialCleanup,
    LocalProfiles,
    WorkTodos,
    WorkTodoSeries,
    WorkCategories,
    WorkspaceOperations,
    WorkDataTables,
    WorkDataRows,
    WorkTableTypes,
    AppPreferenceRows,
    AgentRunRows,
    AgentRunEvents,
    ChatConversations,
    ChatTurns,
    LocalJobRows,
    NotificationAttempts,
    LocalAttachments,
    LocalMemories,
    LocalMemoryState,
    LocalReports,
  ],
)
class AppDatabase extends _$AppDatabase
    implements ModelConfigurationStore, LocalProfileStore {
  AppDatabase(super.executor);
  factory AppDatabase.background(File file) => AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (database) {
        database.execute('PRAGMA busy_timeout = 5000');
        // WAL 让前台与后台维护两个连接互不阻塞（读不阻塞写）。
        // journal_mode 切换可能直接返回 SQLITE_BUSY，busy_timeout 对这一步
        // 不保证等待。各后台 isolate 在有界时间内重试首次建库的竞争。
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (true) {
          try {
            database.execute('PRAGMA journal_mode=WAL');
            break;
          } on SqliteException catch (error) {
            if (error.resultCode != 5 || DateTime.now().isAfter(deadline)) {
              rethrow;
            }
            sleep(const Duration(milliseconds: 25));
          }
        }
      },
    ),
  );
  @override
  int get schemaVersion => 13;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: _migrate,
    onUpgrade: (m, from, to) => _migrate(m),
  );

  // 两个引擎可能同时发现旧版本。拿到 SQLite 写锁后重新读取版本，
  // 并把 schema 与 user_version 放在同一个事务内提交。
  Future<void> _migrate(Migrator m) async {
    await customStatement('BEGIN IMMEDIATE');
    try {
      final row = await customSelect('PRAGMA user_version').getSingle();
      final version = row.data.values.single as int;
      if (version == 0) {
        await m.createAll();
      } else if (version != schemaVersion) {
        await _upgrade(m, version, schemaVersion);
      }
      await customStatement('PRAGMA user_version = $schemaVersion');
      await customStatement('COMMIT');
    } catch (_) {
      await customStatement('ROLLBACK');
      rethrow;
    }
  }

  Future<void> _upgrade(Migrator m, int from, int to) async {
    if (from < 1 || from > 12 || to != 13) {
      throw const SettingsFailure(SettingsFailureCode.storage);
    }
    final unexpected = from < 5
        ? await customSelect(
            "SELECT name FROM sqlite_master WHERE name IN ('agent_run_rows', 'agent_run_events')",
          ).get()
        : const <QueryRow>[];
    if (unexpected.isNotEmpty) {
      throw const SettingsFailure(SettingsFailureCode.storage);
    }
    if (from < 2) await m.createTable(localProfiles);
    if (from < 3) {
      await m.createTable(workTodos);
      await m.createTable(workCategories);
      await m.createTable(workspaceOperations);
      // CREATE TABLE IF NOT EXISTS alone can accept an incompatible table left
      // by a failed/unrecognized migration. Check required audit columns before
      // advancing user_version; any failure rolls the whole migration back.
      await customSelect(
        'SELECT operation_id, request_digest, source, undo_of, receipt, changes, '
        'committed_at FROM workspace_operations LIMIT 0',
      ).get();
      for (final index in allSchemaEntities.whereType<Index>()) {
        if (const {
          'work_todos_category',
          'work_todos_due',
          'work_categories_parent',
        }.contains(index.entityName)) {
          await m.createIndex(index);
        }
      }
    }
    if (from < 4) await m.createTable(appPreferenceRows);
    await customSelect(
      'SELECT singleton_id, version, payload FROM app_preference_rows LIMIT 0',
    ).get();
    if (from < 5) {
      await m.createTable(agentRunRows);
      await m.createTable(agentRunEvents);
    }
    await customSelect(
      'SELECT id, session_id, input_id, revision, status, initial_request, '
      'payload FROM agent_run_rows LIMIT 0',
    ).get();
    await customSelect(
      'SELECT run_id, sequence, payload FROM agent_run_events LIMIT 0',
    ).get();
    if (from < 6) {
      final unexpectedChat = await customSelect(
        "SELECT name FROM sqlite_master WHERE name IN ('chat_conversations', 'chat_turns')",
      ).get();
      if (unexpectedChat.isNotEmpty) {
        throw const SettingsFailure(SettingsFailureCode.storage);
      }
      await m.createTable(chatConversations);
      await m.createTable(chatTurns);
    }
    if (from < 7) {
      final unexpectedSeries = await customSelect(
        "SELECT name FROM sqlite_master WHERE name = 'work_todo_series'",
      ).get();
      if (unexpectedSeries.isNotEmpty) {
        throw const SettingsFailure(SettingsFailureCode.storage);
      }
      await m.createTable(workTodoSeries);
      // When upgrading a pre-v3 database, createTable already used v7 columns.
      if (from >= 3) {
        await m.addColumn(workTodos, workTodos.seriesId);
        await m.addColumn(workTodos, workTodos.occurrenceKey);
        await m.addColumn(workTodos, workTodos.occurrenceIndex);
      }
      for (final index in allSchemaEntities.whereType<Index>()) {
        if (index.entityName.startsWith('work_todos_occurrence')) {
          await m.createIndex(index);
        }
      }
    }
    if (from < 8) {
      final unexpectedJobs = await customSelect(
        "SELECT name FROM sqlite_master WHERE name IN ('local_job_rows', 'notification_attempts')",
      ).get();
      if (unexpectedJobs.isNotEmpty) {
        throw const SettingsFailure(SettingsFailureCode.storage);
      }
      await m.createTable(localJobRows);
      await m.createTable(notificationAttempts);
    }
    if (from < 9) {
      final unexpectedData = await customSelect(
        "SELECT name FROM sqlite_master WHERE name IN ('work_data_tables', 'work_data_rows', 'work_table_types', 'work_data_tables_type', 'work_data_rows_table')",
      ).get();
      if (unexpectedData.isNotEmpty) {
        throw const SettingsFailure(SettingsFailureCode.storage);
      }
      await m.createTable(workDataTables);
      await m.createTable(workDataRows);
      await m.createTable(workTableTypes);
      for (final index in allSchemaEntities.whereType<Index>()) {
        if (index.entityName.startsWith('work_data_')) {
          await m.createIndex(index);
        }
      }
    }
    if (from < 10) {
      final unexpectedAttachments = await customSelect(
        "SELECT name FROM sqlite_master WHERE name = 'local_attachments'",
      ).get();
      if (unexpectedAttachments.isNotEmpty) {
        throw const SettingsFailure(SettingsFailureCode.storage);
      }
      await m.createTable(localAttachments);
    }
    if (from < 11) {
      final unexpectedMemories = await customSelect(
        "SELECT name FROM sqlite_master WHERE name IN ('local_memories', 'local_memory_state')",
      ).get();
      if (unexpectedMemories.isNotEmpty) {
        throw const SettingsFailure(SettingsFailureCode.storage);
      }
      await m.createTable(localMemories);
      await m.createTable(localMemoryState);
    }
    if (from < 12) {
      final unexpectedReports = await customSelect(
        "SELECT name FROM sqlite_master WHERE name = 'local_reports'",
      ).get();
      if (unexpectedReports.isNotEmpty) {
        throw const SettingsFailure(SettingsFailureCode.storage);
      }
      await m.createTable(localReports);
    }
    if (from < 13) {
      final unexpectedAccounts = await customSelect(
        "SELECT name FROM sqlite_master WHERE name = 'provider_accounts'",
      ).get();
      if (unexpectedAccounts.isNotEmpty) {
        throw const SettingsFailure(SettingsFailureCode.storage);
      }
      await m.createTable(providerAccounts);
      await m.addColumn(
        providerConfigurations,
        providerConfigurations.accountId,
      );
      // 已有的单一配置成为第一个账户，Key 引用原样沿用，无需重新填写。
      final existing = await customSelect(
        'SELECT product, region, model, disable_thinking, credential_ref '
        'FROM provider_configurations WHERE id = 1',
      ).getSingleOrNull();
      if (existing != null) {
        await customStatement(
          'INSERT INTO provider_accounts (id, product, region, model, '
          'base_url, disable_thinking, credential_ref, position, '
          'auto_route) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1)',
          [
            migratedAccountId,
            existing.read<String>('product'),
            existing.read<String>('region'),
            existing.read<String>('model'),
            await customBaseUrl(),
            existing.read<bool>('disable_thinking') ? 1 : 0,
            existing.readNullable<String>('credential_ref'),
          ],
        );
        await customStatement(
          'UPDATE provider_configurations SET account_id = ? WHERE id = 1',
          [migratedAccountId],
        );
      }
    }
  }

  /// 升级时由原有单一配置生成的账户 ID。
  static const migratedAccountId = 'acct_primary';

  LocalProfile _profile(LocalProfileRow row) => LocalProfile(
    id: row.localUserId,
    nickname: row.nickname,
    version: row.version,
    createdAt: row.createdAt.toUtc(),
  );

  @override
  Future<LocalProfile> loadOrCreateProfile() async {
    try {
      final existing = await (select(
        localProfiles,
      )..where((r) => r.singletonId.equals(1))).getSingleOrNull();
      if (existing != null) return _profile(existing);
      await into(localProfiles).insert(
        LocalProfilesCompanion.insert(
          singletonId: const Value(1),
          localUserId: createLocalUserId(),
          nickname: '本地用户',
          version: 1,
          createdAt: DateTime.now().toUtc(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
      final row = await (select(
        localProfiles,
      )..where((r) => r.singletonId.equals(1))).getSingle();
      return _profile(row);
    } on ProfileFailure {
      rethrow;
    } catch (_) {
      throw const ProfileFailure(ProfileFailureCode.storage);
    }
  }

  @override
  Future<LocalProfile> renameProfile(
    String name, {
    required int expectedVersion,
  }) async {
    final normalized = normalizeNickname(name);
    try {
      return await transaction(() async {
        final changed =
            await (update(localProfiles)..where(
                  (r) =>
                      r.singletonId.equals(1) &
                      r.version.equals(expectedVersion),
                ))
                .write(
                  LocalProfilesCompanion(
                    nickname: Value(normalized),
                    version: Value(expectedVersion + 1),
                  ),
                );
        if (changed != 1) {
          throw const ProfileFailure(ProfileFailureCode.conflict);
        }
        return _profile(
          await (select(
            localProfiles,
          )..where((r) => r.singletonId.equals(1))).getSingle(),
        );
      });
    } on ProfileFailure {
      rethrow;
    } catch (_) {
      throw const ProfileFailure(ProfileFailureCode.storage);
    }
  }

  @override
  Future<ModelConfiguration> readConfiguration() async {
    final row = await (select(
      providerConfigurations,
    )..where((r) => r.id.equals(1))).getSingleOrNull();
    if (row == null) return ModelConfiguration.empty();
    return ModelConfiguration(
      profile: ModelProfile(
        model: row.model,
        product: ProviderKind.fromWire(row.product),
        region: ProviderRegion.values.byName(row.region),
        revision: row.version,
        disableThinking: row.disableThinking,
        baseUrl: await customBaseUrl(),
      ),
      credentialRef: row.credentialRef,
      version: row.version,
    );
  }

  /// custom（OpenAI 格式中转站）产品的根地址；与 configuration 同事务边界外
  /// 的独立键值行保存，读取配置时并入 profile。
  static const _customBaseUrlId = 2;
  static const _customBaseUrlKey = 'custom_base_url';

  Future<String?> customBaseUrl() async {
    final row = await (select(
      appPreferenceRows,
    )..where((r) => r.singletonId.equals(_customBaseUrlId))).getSingleOrNull();
    if (row == null) return null;
    final payload = (jsonDecode(row.payload) as Map).cast<String, Object?>();
    return payload[_customBaseUrlKey] as String?;
  }

  Future<void> _writeCustomBaseUrl(String? value) async {
    final existing = await customBaseUrl();
    if (existing == value) return;
    if (value == null) {
      await (delete(
        appPreferenceRows,
      )..where((r) => r.singletonId.equals(_customBaseUrlId))).go();
      return;
    }
    await into(appPreferenceRows).insertOnConflictUpdate(
      AppPreferenceRowsCompanion.insert(
        singletonId: Value(_customBaseUrlId),
        version: _clockVersion(),
        payload: jsonEncode({_customBaseUrlKey: value}),
      ),
    );
  }

  int _clockVersion() => DateTime.now().toUtc().microsecondsSinceEpoch;

  @override
  Future<void> stageCredential(String reference) async {
    await into(credentialCleanup)
        .insert(CredentialCleanupCompanion.insert(reference: reference));
  }

  @override
  Future<List<String>> pendingCleanup() async =>
      (await select(credentialCleanup).get()).map((r) => r.reference).toList();
  @override
  Future<void> finishCleanup(String reference) async {
    await (delete(
      credentialCleanup,
    )..where((r) => r.reference.equals(reference))).go();
  }

  /// 当前配置关联的账户 ID。
  Future<String?> activeAccountId() async {
    final row = await (select(
      providerConfigurations,
    )..where((r) => r.id.equals(1))).getSingleOrNull();
    return row?.accountId;
  }

  /// 某个 Key 引用不再被当前配置或任何账户使用时，排队等待从系统
  /// 安全存储里删除。仍在使用的引用绝不排队。
  Future<void> releaseCredential(String? reference) async {
    if (reference == null) return;
    final config = await (select(
      providerConfigurations,
    )..where((r) => r.id.equals(1))).getSingleOrNull();
    if (config?.credentialRef == reference) return;
    final holders = await (select(
      providerAccounts,
    )..where((r) => r.credentialRef.equals(reference))).get();
    if (holders.isNotEmpty) return;
    await into(credentialCleanup).insert(
      CredentialCleanupCompanion.insert(reference: reference),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// 写入当前配置行。调用方负责版本检查与事务。
  Future<void> writeActiveConfiguration(
    ModelConfiguration next, {
    required String? accountId,
  }) async {
    await into(providerConfigurations).insertOnConflictUpdate(
      ProviderConfigurationsCompanion.insert(
        id: const Value(1),
        product: next.profile.product.wireId,
        region: next.profile.region.name,
        model: next.profile.model,
        disableThinking: next.profile.disableThinking,
        version: next.version,
        credentialRef: Value(next.credentialRef),
        accountId: Value(accountId),
      ),
    );
    await _writeCustomBaseUrl(
      next.profile.descriptor.needsBaseUrl ? next.profile.baseUrl : null,
    );
  }

  @override
  Future<void> commit(
    ModelConfiguration next, {
    required int expectedVersion,
  }) => transaction(() async {
    final old = await readConfiguration();
    if (old.version != expectedVersion || next.version != expectedVersion + 1) {
      throw const SettingsFailure(SettingsFailureCode.conflict);
    }
    // 直接编辑当前配置时，同步它背后的账户；还没有账户就建一个，
    // 这样账户列表始终包含正在使用的那一个。
    var accountId = await activeAccountId();
    final account = accountId == null
        ? null
        : await (select(
            providerAccounts,
          )..where((r) => r.id.equals(accountId!))).getSingleOrNull();
    if (account != null) {
      await (update(
        providerAccounts,
      )..where((r) => r.id.equals(account.id))).write(
        ProviderAccountsCompanion(
          product: Value(next.profile.product.wireId),
          region: Value(next.profile.region.name),
          model: Value(next.profile.model),
          baseUrl: Value(
            next.profile.descriptor.needsBaseUrl ? next.profile.baseUrl : null,
          ),
          disableThinking: Value(next.profile.disableThinking),
          credentialRef: Value(next.credentialRef),
        ),
      );
    } else if (next.credentialRef != null) {
      accountId = 'acct_${next.credentialRef!.split('.').last}';
      final positions = await (select(providerAccounts)).get();
      await into(providerAccounts).insert(
        ProviderAccountsCompanion.insert(
          id: accountId,
          product: next.profile.product.wireId,
          region: next.profile.region.name,
          model: next.profile.model,
          baseUrl: Value(
            next.profile.descriptor.needsBaseUrl ? next.profile.baseUrl : null,
          ),
          disableThinking: next.profile.disableThinking,
          credentialRef: Value(next.credentialRef),
          position: positions.length,
          autoRoute: true,
        ),
      );
    } else {
      accountId = null;
    }
    await writeActiveConfiguration(next, accountId: accountId);
    if (next.credentialRef != null) await finishCleanup(next.credentialRef!);
    if (old.credentialRef != next.credentialRef) {
      await releaseCredential(old.credentialRef);
    }
  });
}
