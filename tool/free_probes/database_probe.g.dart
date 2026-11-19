// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_probe.dart';

// ignore_for_file: type=lint
class $ProbeItemsTable extends ProbeItems
    with TableInfo<$ProbeItemsTable, ProbeItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProbeItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'probe_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProbeItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProbeItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProbeItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ProbeItemsTable createAlias(String alias) {
    return $ProbeItemsTable(attachedDatabase, alias);
  }
}

class ProbeItem extends DataClass implements Insertable<ProbeItem> {
  final String id;
  final String title;
  final int version;
  const ProbeItem({
    required this.id,
    required this.title,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['version'] = Variable<int>(version);
    return map;
  }

  ProbeItemsCompanion toCompanion(bool nullToAbsent) {
    return ProbeItemsCompanion(
      id: Value(id),
      title: Value(title),
      version: Value(version),
    );
  }

  factory ProbeItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProbeItem(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'version': serializer.toJson<int>(version),
    };
  }

  ProbeItem copyWith({String? id, String? title, int? version}) => ProbeItem(
    id: id ?? this.id,
    title: title ?? this.title,
    version: version ?? this.version,
  );
  ProbeItem copyWithCompanion(ProbeItemsCompanion data) {
    return ProbeItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProbeItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProbeItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.version == this.version);
}

class ProbeItemsCompanion extends UpdateCompanion<ProbeItem> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> version;
  final Value<int> rowid;
  const ProbeItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProbeItemsCompanion.insert({
    required String id,
    required String title,
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<ProbeItem> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProbeItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ProbeItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProbeItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProbeReceiptsTable extends ProbeReceipts
    with TableInfo<$ProbeReceiptsTable, ProbeReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProbeReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalRequestMeta = const VerificationMeta(
    'canonicalRequest',
  );
  @override
  late final GeneratedColumn<String> canonicalRequest = GeneratedColumn<String>(
    'canonical_request',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _committedResultMeta = const VerificationMeta(
    'committedResult',
  );
  @override
  late final GeneratedColumn<String> committedResult = GeneratedColumn<String>(
    'committed_result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    canonicalRequest,
    committedResult,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'probe_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProbeReceipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('canonical_request')) {
      context.handle(
        _canonicalRequestMeta,
        canonicalRequest.isAcceptableOrUnknown(
          data['canonical_request']!,
          _canonicalRequestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalRequestMeta);
    }
    if (data.containsKey('committed_result')) {
      context.handle(
        _committedResultMeta,
        committedResult.isAcceptableOrUnknown(
          data['committed_result']!,
          _committedResultMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_committedResultMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  ProbeReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProbeReceipt(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      canonicalRequest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_request'],
      )!,
      committedResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}committed_result'],
      )!,
    );
  }

  @override
  $ProbeReceiptsTable createAlias(String alias) {
    return $ProbeReceiptsTable(attachedDatabase, alias);
  }
}

class ProbeReceipt extends DataClass implements Insertable<ProbeReceipt> {
  final String operationId;
  final String canonicalRequest;
  final String committedResult;
  const ProbeReceipt({
    required this.operationId,
    required this.canonicalRequest,
    required this.committedResult,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['canonical_request'] = Variable<String>(canonicalRequest);
    map['committed_result'] = Variable<String>(committedResult);
    return map;
  }

  ProbeReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ProbeReceiptsCompanion(
      operationId: Value(operationId),
      canonicalRequest: Value(canonicalRequest),
      committedResult: Value(committedResult),
    );
  }

  factory ProbeReceipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProbeReceipt(
      operationId: serializer.fromJson<String>(json['operationId']),
      canonicalRequest: serializer.fromJson<String>(json['canonicalRequest']),
      committedResult: serializer.fromJson<String>(json['committedResult']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'canonicalRequest': serializer.toJson<String>(canonicalRequest),
      'committedResult': serializer.toJson<String>(committedResult),
    };
  }

  ProbeReceipt copyWith({
    String? operationId,
    String? canonicalRequest,
    String? committedResult,
  }) => ProbeReceipt(
    operationId: operationId ?? this.operationId,
    canonicalRequest: canonicalRequest ?? this.canonicalRequest,
    committedResult: committedResult ?? this.committedResult,
  );
  ProbeReceipt copyWithCompanion(ProbeReceiptsCompanion data) {
    return ProbeReceipt(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      canonicalRequest: data.canonicalRequest.present
          ? data.canonicalRequest.value
          : this.canonicalRequest,
      committedResult: data.committedResult.present
          ? data.committedResult.value
          : this.committedResult,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProbeReceipt(')
          ..write('operationId: $operationId, ')
          ..write('canonicalRequest: $canonicalRequest, ')
          ..write('committedResult: $committedResult')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(operationId, canonicalRequest, committedResult);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProbeReceipt &&
          other.operationId == this.operationId &&
          other.canonicalRequest == this.canonicalRequest &&
          other.committedResult == this.committedResult);
}

class ProbeReceiptsCompanion extends UpdateCompanion<ProbeReceipt> {
  final Value<String> operationId;
  final Value<String> canonicalRequest;
  final Value<String> committedResult;
  final Value<int> rowid;
  const ProbeReceiptsCompanion({
    this.operationId = const Value.absent(),
    this.canonicalRequest = const Value.absent(),
    this.committedResult = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProbeReceiptsCompanion.insert({
    required String operationId,
    required String canonicalRequest,
    required String committedResult,
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       canonicalRequest = Value(canonicalRequest),
       committedResult = Value(committedResult);
  static Insertable<ProbeReceipt> custom({
    Expression<String>? operationId,
    Expression<String>? canonicalRequest,
    Expression<String>? committedResult,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (canonicalRequest != null) 'canonical_request': canonicalRequest,
      if (committedResult != null) 'committed_result': committedResult,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProbeReceiptsCompanion copyWith({
    Value<String>? operationId,
    Value<String>? canonicalRequest,
    Value<String>? committedResult,
    Value<int>? rowid,
  }) {
    return ProbeReceiptsCompanion(
      operationId: operationId ?? this.operationId,
      canonicalRequest: canonicalRequest ?? this.canonicalRequest,
      committedResult: committedResult ?? this.committedResult,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (canonicalRequest.present) {
      map['canonical_request'] = Variable<String>(canonicalRequest.value);
    }
    if (committedResult.present) {
      map['committed_result'] = Variable<String>(committedResult.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProbeReceiptsCompanion(')
          ..write('operationId: $operationId, ')
          ..write('canonicalRequest: $canonicalRequest, ')
          ..write('committedResult: $committedResult, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProbeDatabase extends GeneratedDatabase {
  _$ProbeDatabase(QueryExecutor e) : super(e);
  $ProbeDatabaseManager get managers => $ProbeDatabaseManager(this);
  late final $ProbeItemsTable probeItems = $ProbeItemsTable(this);
  late final $ProbeReceiptsTable probeReceipts = $ProbeReceiptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    probeItems,
    probeReceipts,
  ];
}

typedef $$ProbeItemsTableCreateCompanionBuilder = ProbeItemsCompanion Function({
  required String id,
  required String title,
  Value<int> version,
  Value<int> rowid,
});
typedef $$ProbeItemsTableUpdateCompanionBuilder = ProbeItemsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<int> version,
  Value<int> rowid,
});

class $$ProbeItemsTableFilterComposer
    extends Composer<_$ProbeDatabase, $ProbeItemsTable> {
  $$ProbeItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProbeItemsTableOrderingComposer
    extends Composer<_$ProbeDatabase, $ProbeItemsTable> {
  $$ProbeItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProbeItemsTableAnnotationComposer
    extends Composer<_$ProbeDatabase, $ProbeItemsTable> {
  $$ProbeItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ProbeItemsTableTableManager
    extends
        RootTableManager<
          _$ProbeDatabase,
          $ProbeItemsTable,
          ProbeItem,
          $$ProbeItemsTableFilterComposer,
          $$ProbeItemsTableOrderingComposer,
          $$ProbeItemsTableAnnotationComposer,
          $$ProbeItemsTableCreateCompanionBuilder,
          $$ProbeItemsTableUpdateCompanionBuilder,
          (
            ProbeItem,
            BaseReferences<_$ProbeDatabase, $ProbeItemsTable, ProbeItem>,
          ),
          ProbeItem,
          PrefetchHooks Function()
        > {
  $$ProbeItemsTableTableManager(_$ProbeDatabase db, $ProbeItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProbeItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProbeItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProbeItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProbeItemsCompanion(
                id: id,
                title: title,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProbeItemsCompanion.insert(
                id: id,
                title: title,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProbeItemsTable, ProbeItem>(table),
                  BaseReferences<_$ProbeDatabase, $ProbeItemsTable, ProbeItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProbeItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProbeDatabase,
      $ProbeItemsTable,
      ProbeItem,
      $$ProbeItemsTableFilterComposer,
      $$ProbeItemsTableOrderingComposer,
      $$ProbeItemsTableAnnotationComposer,
      $$ProbeItemsTableCreateCompanionBuilder,
      $$ProbeItemsTableUpdateCompanionBuilder,
      (ProbeItem, BaseReferences<_$ProbeDatabase, $ProbeItemsTable, ProbeItem>),
      ProbeItem,
      PrefetchHooks Function()
    >;
typedef $$ProbeReceiptsTableCreateCompanionBuilder =
    ProbeReceiptsCompanion Function({
      required String operationId,
      required String canonicalRequest,
      required String committedResult,
      Value<int> rowid,
    });
typedef $$ProbeReceiptsTableUpdateCompanionBuilder =
    ProbeReceiptsCompanion Function({
      Value<String> operationId,
      Value<String> canonicalRequest,
      Value<String> committedResult,
      Value<int> rowid,
    });

class $$ProbeReceiptsTableFilterComposer
    extends Composer<_$ProbeDatabase, $ProbeReceiptsTable> {
  $$ProbeReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalRequest => $composableBuilder(
    column: $table.canonicalRequest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get committedResult => $composableBuilder(
    column: $table.committedResult,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProbeReceiptsTableOrderingComposer
    extends Composer<_$ProbeDatabase, $ProbeReceiptsTable> {
  $$ProbeReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalRequest => $composableBuilder(
    column: $table.canonicalRequest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get committedResult => $composableBuilder(
    column: $table.committedResult,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProbeReceiptsTableAnnotationComposer
    extends Composer<_$ProbeDatabase, $ProbeReceiptsTable> {
  $$ProbeReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalRequest => $composableBuilder(
    column: $table.canonicalRequest,
    builder: (column) => column,
  );

  GeneratedColumn<String> get committedResult => $composableBuilder(
    column: $table.committedResult,
    builder: (column) => column,
  );
}

class $$ProbeReceiptsTableTableManager
    extends
        RootTableManager<
          _$ProbeDatabase,
          $ProbeReceiptsTable,
          ProbeReceipt,
          $$ProbeReceiptsTableFilterComposer,
          $$ProbeReceiptsTableOrderingComposer,
          $$ProbeReceiptsTableAnnotationComposer,
          $$ProbeReceiptsTableCreateCompanionBuilder,
          $$ProbeReceiptsTableUpdateCompanionBuilder,
          (
            ProbeReceipt,
            BaseReferences<_$ProbeDatabase, $ProbeReceiptsTable, ProbeReceipt>,
          ),
          ProbeReceipt,
          PrefetchHooks Function()
        > {
  $$ProbeReceiptsTableTableManager(
    _$ProbeDatabase db,
    $ProbeReceiptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProbeReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProbeReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProbeReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> canonicalRequest = const Value.absent(),
                Value<String> committedResult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProbeReceiptsCompanion(
                operationId: operationId,
                canonicalRequest: canonicalRequest,
                committedResult: committedResult,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String canonicalRequest,
                required String committedResult,
                Value<int> rowid = const Value.absent(),
              }) => ProbeReceiptsCompanion.insert(
                operationId: operationId,
                canonicalRequest: canonicalRequest,
                committedResult: committedResult,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProbeReceiptsTable, ProbeReceipt>(table),
                  BaseReferences<
                    _$ProbeDatabase,
                    $ProbeReceiptsTable,
                    ProbeReceipt
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProbeReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProbeDatabase,
      $ProbeReceiptsTable,
      ProbeReceipt,
      $$ProbeReceiptsTableFilterComposer,
      $$ProbeReceiptsTableOrderingComposer,
      $$ProbeReceiptsTableAnnotationComposer,
      $$ProbeReceiptsTableCreateCompanionBuilder,
      $$ProbeReceiptsTableUpdateCompanionBuilder,
      (
        ProbeReceipt,
        BaseReferences<_$ProbeDatabase, $ProbeReceiptsTable, ProbeReceipt>,
      ),
      ProbeReceipt,
      PrefetchHooks Function()
    >;

class $ProbeDatabaseManager {
  final _$ProbeDatabase _db;
  $ProbeDatabaseManager(this._db);
  $$ProbeItemsTableTableManager get probeItems =>
      $$ProbeItemsTableTableManager(_db, _db.probeItems);
  $$ProbeReceiptsTableTableManager get probeReceipts =>
      $$ProbeReceiptsTableTableManager(_db, _db.probeReceipts);
}
