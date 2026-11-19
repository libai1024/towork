enum DataChangeSource { ai, manual }

/// 数据表字段类型（07-data-tables.md F6.1）。
enum DataFieldType {
  text,
  number,
  money,
  date,
  datetime,
  selection,
  boolean;

  /// Parse the existing in-memory schema names, including the currency alias.
  /// Unknown types must not silently acquire text-field validation rules.
  static DataFieldType parse(String value) => switch (value) {
    'text' => text,
    'number' => number,
    'money' || 'currency' => money,
    'date' => date,
    'datetime' => datetime,
    'enum' => selection,
    'bool' => boolean,
    _ => throw FormatException('Unknown data field type', value),
  };
}

const Object _keep = Object();

/// 变更动作（07-data-tables.md §8.3）。
enum DataChangeAction { create, update, delete }

class DataColumnDef {
  DataColumnDef({
    required this.name,
    required this.type,
    this.isRequired = false,
    List<String> enumOptions = const [],
    this.unit,
    this.id,
    this.scale = 2,
  }) : enumOptions = List<String>.unmodifiable(enumOptions),
       fieldType = DataFieldType.parse(type);

  final String? id;
  final int scale;
  final String name;

  /// text / number / money（旧别名 currency）/ date / datetime / enum / bool
  final String type;

  /// 必填（新建行时校验，标签后红 *）。
  final bool isRequired;

  /// type == enum 时的可选项。
  final List<String> enumOptions;

  /// number/money 的单位后缀（如「股」「分钟」）。
  final String? unit;

  final DataFieldType fieldType;

  DataColumnDef copyWith({
    String? name,
    String? type,
    bool? isRequired,
    List<String>? enumOptions,
    Object? unit = _keep,
  }) => DataColumnDef(
    id: id,
    scale: scale,
    name: name ?? this.name,
    type: type ?? this.type,
    isRequired: isRequired ?? this.isRequired,
    enumOptions: enumOptions ?? this.enumOptions,
    unit: identical(unit, _keep) ? this.unit : unit as String?,
  );
}

/// User-defined grouping for business data tables, independent of todo categories.
class DataTableType {
  const DataTableType({required this.id, required this.name, this.version = 1});
  final int version;

  final String id;
  final String name;
}

class DataTableDef {
  DataTableDef({
    required this.id,
    required this.name,
    required List<DataColumnDef> columns,
    required this.createdAt,
    this.description = '',
    this.iconKey = 'table',
    this.archived = false,
    this.typeId,
    this.version = 1,
    this.schemaVersion = 1,
  }) : columns = List<DataColumnDef>.unmodifiable(columns);

  final String id;
  final String name;
  final int version;
  final int schemaVersion;
  final List<DataColumnDef> columns;
  final DateTime createdAt;

  /// 表名下方/设置里的说明。
  final String description;

  /// 展示图标键（UI 层映射到 Lucide 图标）。
  final String iconKey;

  final bool archived;

  /// Null retains compatibility with existing, unassigned tables.
  final String? typeId;

  DataTableDef copyWith({
    String? name,
    String? description,
    String? iconKey,
    List<DataColumnDef>? columns,
    bool? archived,
    int? schemaVersion,
    Object? typeId = _keep,
  }) {
    return DataTableDef(
      id: id,
      version: version,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      name: name ?? this.name,
      columns: columns ?? this.columns,
      createdAt: createdAt,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      archived: archived ?? this.archived,
      typeId: identical(typeId, _keep) ? this.typeId : typeId as String?,
    );
  }
}

class DataRow {
  DataRow({
    required this.id,
    required this.tableId,
    required Map<String, String> values,
    required this.updatedAt,
    this.source = DataChangeSource.manual,
    this.version = 1,
  }) : values = Map<String, String>.unmodifiable(values);

  final String id;
  final String tableId;
  final int version;
  final Map<String, String> values;
  final DateTime updatedAt;

  /// 记录来源；本地持久化保留创建来源，每次修改者见变更历史。
  final DataChangeSource source;

  DataRow copyWith({
    Map<String, String>? values,
    DateTime? updatedAt,
    DataChangeSource? source,
  }) {
    return DataRow(
      id: id,
      tableId: tableId,
      version: version,
      values: values ?? this.values,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
    );
  }
}

class DataChangeLog {
  DataChangeLog({
    required this.id,
    required this.tableId,
    required this.rowId,
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.source,
    required this.createdAt,
    this.action = DataChangeAction.update,
    this.reason,
    this.sourceLabel,
    Map<String, Object?>? persistedValues,
    Map<String, String>? beforeValues,
    Map<String, String>? afterValues,
  }) : persistedValues = persistedValues == null
           ? null
           : Map.unmodifiable(persistedValues),
       beforeValues = beforeValues == null
           ? null
           : Map<String, String>.unmodifiable(beforeValues),
       afterValues = afterValues == null
           ? null
           : Map<String, String>.unmodifiable(afterValues);

  final String id;
  final String tableId;
  final String rowId;
  final String field;
  final String oldValue;
  final String newValue;
  final DataChangeSource source;
  final DateTime createdAt;

  final DataChangeAction action;

  /// AI 写入的理由（07-data-tables.md §3.4 reason 气泡）。
  final String? reason;
  final Map<String, Object?>? persistedValues;

  /// 来源说明（如「截图「持仓_0921.png」的分析」）。
  final String? sourceLabel;

  /// 多字段变更/新建/删除时的整行快照；为 null 时按 field/oldValue/newValue 单字段渲染。
  final Map<String, String>? beforeValues;
  final Map<String, String>? afterValues;
}

/// AI 待确认：单字段级变更（07-data-tables.md §8.4）。
class PendingFieldChange {
  const PendingFieldChange({
    required this.field,
    this.oldValue,
    this.newValue,
    this.confidence = 1,
  });

  final String field;
  final String? oldValue;
  final String? newValue;

  /// 视觉模型置信度（0–1），< 0.8 时 UI 标 orange「AI 不太确定」。
  final double confidence;
}

/// AI 待确认：一条行级变更（新增/修改/删除）。
class PendingRowChange {
  PendingRowChange({
    required this.id,
    required this.action,
    required this.rowLabel,
    this.rowId,
    List<PendingFieldChange> fields = const [],
    Map<String, String> createValues = const {},
  }) : fields = List<PendingFieldChange>.unmodifiable(fields),
       createValues = Map<String, String>.unmodifiable(createValues);

  final String id;
  final DataChangeAction action;

  /// 修改/删除的目标行；新增为 null。
  final String? rowId;

  /// 行标识（首字段值），如「贵州茅台」。
  final String rowLabel;

  /// update/delete 的字段级 diff；delete 时为当前值快照。
  final List<PendingFieldChange> fields;

  /// create 的新行值。
  final Map<String, String> createValues;
}

/// AI 待确认批次（一次推送/一次截图分析的结果）。
class PendingAiBatch {
  PendingAiBatch({
    required this.id,
    required this.tableId,
    required this.reason,
    required this.sourceLabel,
    required this.createdAt,
    List<PendingRowChange> changes = const [],
  }) : changes = List<PendingRowChange>.unmodifiable(changes);

  final String id;
  final String tableId;
  final String reason;
  final String sourceLabel;
  final DateTime createdAt;
  final List<PendingRowChange> changes;
}

/// 表模板（07-data-tables.md §3.1 模板区）。
class DataTableTemplate {
  DataTableTemplate({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.description,
    required List<DataColumnDef> columns,
    List<Map<String, String>> seedRows = const [],
  }) : columns = List<DataColumnDef>.unmodifiable(columns),
       seedRows = List<Map<String, String>>.unmodifiable(
         seedRows.map((row) => Map<String, String>.unmodifiable(row)),
       );

  final String id;
  final String name;
  final String iconKey;
  final String description;
  final List<DataColumnDef> columns;
  final List<Map<String, String>> seedRows;
}

/// 应用侧自统计额度（规范 §7.2）：5h 窗口 / 周 / 月。
