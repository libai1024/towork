import 'table_schema_agent_tools.dart';
import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/data_tables/business_queries.dart';
import '../domain/data_tables/business_validation.dart';
import '../domain/workspace/workspace_commands.dart';
import '../domain/workspace/workspace_validation.dart';

/// Typed row commands, sharing the same permission, transaction and undo path as
/// manual edits. Schema changes are deliberately separate business operations.
class BusinessAgentTools {
  static const writes = {
    ...TableSchemaAgentTools.names,
    'data_row_create',
    'data_row_update',
    'data_row_delete',
  };
  static const _id = {'type': 'string'};
  static const _version = {'type': 'integer', 'minimum': 1};
  static const _page = {
    'limit': {'type': 'integer', 'minimum': 1, 'maximum': 20},
    'page_token': {'type': 'string', 'maxLength': 1024},
  };
  static const _table = {'table_id': _id, 'expected_table_version': _version};
  static const _row = {..._table, 'id': _id, 'expected_version': _version};
  static const _uncertainty = {
    'uncertain_field_ids': {
      'type': 'array',
      'items': _id,
      'maxItems': 100,
      'uniqueItems': true,
      'description': 'Fields whose extracted values need human verification. For image extraction this is required; [] only if every supplied cell is clear. Never invent missing required values. Non-empty forces review even in automatic mode.',
    },
  };
  static const _values = {
    'type': 'object',
    'maxProperties': 100,
    'additionalProperties': {
      'type': ['string', 'boolean', 'null'],
    },
    'description': 'Stable field IDs from data_table_get. Numbers and money must be decimal strings, boolean is JSON boolean, date YYYY-MM-DD, datetime UTC ISO-8601. Null clears an optional cell. Never copy truncated values.',
  };
  static final List<JsonObject> schemas = List.unmodifiable([
    ...TableSchemaAgentTools.schemas,
    _schema(
      'data_table_list',
      'Find local business tables by name. Clarify ambiguous matches. Archived tables excluded unless requested. Queries see the pre-write snapshot. Pagination requires identical arguments; cursor_stale means restart.',
      {
        ..._page,
        'query': {'type': 'string', 'maxLength': 200},
        'include_archived': {'type': 'boolean'},
      },
      [],
    ),
    _schema(
      'data_table_get',
      'Read paginated field definitions (stable IDs, types, required, scale, option_count). With field_id, read paginated selection options under options.items. Use the returned table version for writes. Keep page arguments unchanged.',
      {..._table, ..._page, 'field_id': _id},
      ['table_id'],
    ),
    _schema(
      'data_row_list',
      'Find rows within a table by server-side SQL filtering, sorting and paging; only the returned page is materialized. text/selection filters: eq, contains; number/money/date/datetime: eq,gt,ge,lt,le (money eq keeps scale); boolean: eq. query searches any string cell case-insensitively. sort_field_id orders by that cell (missing values last), id breaks ties; ID ascending by default. Bounded previews; omitted/truncated fields are explicit. Read full cells with data_row_get before replacing their content. All queries see the pre-write snapshot.',
      {
        ..._table,
        ..._page,
        'query': {'type': 'string', 'maxLength': 200},
        'field_ids': {
          'type': 'array',
          'items': _id,
          'minItems': 1,
          'maxItems': 8,
          'uniqueItems': true,
        },
        'filters': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'field_id': _id,
              'op': {'type': 'string'},
              'value': <String, Object?>{},
            },
            'required': ['field_id', 'op', 'value'],
            'additionalProperties': false,
          },
          'maxItems': 4,
        },
        'sort_field_id': _id,
        'sort_desc': {'type': 'boolean'},
      },
      ['table_id'],
    ),
    _schema(
      'data_row_get',
      'Read one exact cell, preserving JSON types. Text uses Unicode code point offsets; subsequent segments require both returned row version and table version. Never replace a full cell with one segment. present distinguishes missing from null.',
      {
        ..._row,
        'field_id': _id,
        'offset': {'type': 'integer', 'minimum': 0, 'maximum': 100000},
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 4000},
      },
      ['table_id', 'id', 'field_id'],
    ),
    _schema(
      'data_row_create',
      'Create a row in a previously queried table. Supply all required cells. IDs and provenance are assigned by the app.',
      {..._table, ..._uncertainty, 'values': _values},
      ['table_id', 'expected_table_version', 'values'],
    ),
    _schema(
      'data_row_update',
      'Edit a queried row at the exact table and row versions. values is a sparse cell patch: omitted fields stay unchanged, null clears optional fields. Do not send a full row copied from a preview.',
      {
        ..._row,
        ..._uncertainty,
        'values': {..._values, 'minProperties': 1},
      },
      [
        'table_id',
        'expected_table_version',
        'id',
        'expected_version',
        'values',
      ],
    ),
    _schema(
      'data_row_delete',
      'Delete exactly the queried row at the exact table and row versions, subject to the app permission policy.',
      _row,
      ['table_id', 'expected_table_version', 'id', 'expected_version'],
    ),
  ]);
  static JsonObject _schema(
    String name,
    String description,
    JsonObject fields,
    List<String> required,
  ) => immutableJson({
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': fields,
        'required': required,
        'additionalProperties': false,
      },
    },
  });

  static JsonObject prepare({
    required String name,
    required JsonObject args,
    required String callId,
    required String suffix,
    required String inputId,
    required WorkspaceSnapshot snapshot,
    required DateTime now,
  }) {
    if (TableSchemaAgentTools.names.contains(name)) {
      return TableSchemaAgentTools.prepare(
        name: name,
        args: args,
        callId: callId,
        suffix: suffix,
        snapshot: snapshot,
        now: now,
      );
    }
    final create = name == 'data_row_create',
        deleting = name == 'data_row_delete';
    if (!writes.contains(name)) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final keys = {
      ..._table.keys,
      if (!create) ...['id', 'expected_version'],
      if (!deleting) 'values',
    };
    BusinessQueries.keys(args, {
      ...keys,
      if (!deleting) 'uncertain_field_ids',
    }, keys);
    if (args['expected_table_version'] == null ||
        !create && args['expected_version'] == null) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final table = BusinessQueries.table(
      snapshot,
      args['table_id'],
      args['expected_table_version'],
    );
    final id = create ? 'br_$suffix' : BusinessQueries.id(args['id']);
    final before = snapshot.find(WorkspaceEntityKind.dataRow, id);
    if (create
        ? before != null
        : before == null ||
              before.isDeleted ||
              before.data['table_id'] != table.id) {
      throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
    }
    if (before != null) {
      BusinessQueries.checkVersion(before, args['expected_version']);
    }
    final rawValues = deleting ? <String, Object?>{} : args['values'];
    if (rawValues is! JsonObject || !create && !deleting && rawValues.isEmpty) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final uncertain = args['uncertain_field_ids'] ?? <String>[];
    if (uncertain is! List ||
        uncertain.length > 100 ||
        uncertain.any((id) => id is! String || !rawValues.containsKey(id)) ||
        uncertain.toSet().length != uncertain.length) {
      throw const AgentFailure(AgentFailureCode.invalid);
    }
    final patch = deleting
        ? <String, Object?>{}
        : <String, Object?>{
            if (create) ...{
              'table_id': table.id,
              'source': 'ai',
              'source_message_id': inputId,
            },
            'values': normalizeBusinessValues(table.data, {
              ...?before?.data['values'] as JsonObject?,
              ...rawValues,
            }),
          };
    final after = deleting
        ? null
        : applyWorkspacePatch(
            WorkspaceEntityKind.dataRow,
            before?.data,
            patch,
            now,
          );
    return immutableJson({
      'tool_call_id': callId,
      'name': name,
      'operation': create
          ? 'create'
          : deleting
          ? 'delete'
          : 'edit',
      'before': before?.toJson(),
      'after': after,
      'requires_review': true,
      'uncertain_field_ids': uncertain,
      'business_intent': {'args': args, 'suffix': suffix, 'input_id': inputId},
      'business_table': {
        'id': table.id,
        'version': table.version,
        'name': table.data['name'],
        'fields': [
          for (final f in BusinessQueries.fields(table))
            {
              'id': f['id'],
              'name': f['name'],
              'type': f['type'],
              'unit': f['unit'],
            },
        ],
      },
      'mutation': WorkspaceMutation(
        actionId: 'ba_$suffix',
        kind: WorkspaceEntityKind.dataRow,
        entityId: id,
        mutation: create
            ? WorkspaceMutationKind.create
            : deleting
            ? WorkspaceMutationKind.delete
            : WorkspaceMutationKind.update,
        expectedVersion: before?.version,
        patch: after ?? {},
      ).toJson(),
    });
  }

  /// Refresh sparse intent against current values and schema, then the caller
  /// persists a NEW preview requiring explicit approval, including in auto mode.
  static JsonObject refresh(
    JsonObject call,
    WorkspaceSnapshot snapshot,
    DateTime now,
  ) {
    if (call['table_intent'] != null) {
      return TableSchemaAgentTools.refresh(call, snapshot, now);
    }
    final intent = call['business_intent']! as JsonObject;
    final args = intent['args']! as JsonObject;
    final table = BusinessQueries.table(snapshot, args['table_id'], null);
    final create = call['name'] == 'data_row_create';
    final row = create
        ? null
        : snapshot.find(
            WorkspaceEntityKind.dataRow,
            BusinessQueries.id(args['id']),
          );
    if (!create && (row == null || row.isDeleted)) {
      throw const WorkspaceFailure(WorkspaceFailureCode.notFound);
    }
    return prepare(
      name: call['name']! as String,
      args: {
        ...args,
        'expected_table_version': table.version,
        if (!create) 'expected_version': row!.version,
      },
      callId: call['tool_call_id']! as String,
      suffix: intent['suffix']! as String,
      inputId: intent['input_id']! as String,
      snapshot: snapshot,
      now: now,
    );
  }

  /// A table rename/schema edit must invalidate an already displayed preview,
  /// even if the row itself has not changed. Called inside the commit transaction.
  static void validateCurrent(JsonObject call, WorkspaceSnapshot snapshot) {
    final table = call['business_table'];
    if (table is JsonObject) {
      BusinessQueries.table(snapshot, table['id'], table['version']);
    }
  }
}
