import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/data_tables/business_queries.dart';
import '../domain/data_tables/business_validation.dart';
import '../domain/workspace/workspace_commands.dart';
import 'agent_tool_registry.dart';

/// Table definitions use sparse field operations so paginated reads can never
/// accidentally replace an unseen part of a schema. IDs belong to the app.
class TableSchemaAgentTools {
  static const names = {'data_table_create', 'data_table_update'};
  static const _fieldProperties = {
    'name': {'type': 'string', 'minLength': 1, 'maxLength': 200},
    'required': {'type': 'boolean'},
    'options': {
      'type': 'array',
      'items': {'type': 'string', 'minLength': 1, 'maxLength': 200},
      'maxItems': 100,
      'uniqueItems': true,
    },
    'unit': {
      'type': ['string', 'null'],
      'maxLength': 80,
    },
  };
  static const _newField = {
    'type': 'object',
    'properties': {
      ..._fieldProperties,
      'type': {
        'type': 'string',
        'enum': [
          'text',
          'number',
          'money',
          'date',
          'datetime',
          'selection',
          'boolean',
        ],
      },
      'scale': {'type': 'integer', 'minimum': 0, 'maximum': 6},
    },
    'required': ['name', 'type'],
    'additionalProperties': false,
  };
  static const _metadata = {
    'name': {'type': 'string', 'minLength': 1, 'maxLength': 200},
    'description': {'type': 'string', 'maxLength': 10000},
  };
  static final schemas = [
    agentToolSchema(
      'data_table_create',
      'Propose a new business table. Always waits for user confirmation on the preview card. The app assigns table and field IDs. Selection fields need options; scale only applies to money (default 2). Add rows in a later batch using the committed IDs.',
      {
        ..._metadata,
        'fields': {
          'type': 'array',
          'items': _newField,
          'minItems': 1,
          'maxItems': 100,
        },
      },
      required: ['name', 'fields'],
    ),
    agentToolSchema(
      'data_table_update',
      'Propose sparse changes to a queried table at its exact version. Always waits for user confirmation. Omitted fields and metadata stay unchanged. Use queried field IDs for update/remove. Existing field type and money scale stay fixed. Removing a field containing data or making existing rows invalid is rejected. Inspect current rows first.',
      {
        'table_id': {'type': 'string'},
        'expected_table_version': {'type': 'integer', 'minimum': 1},
        'patch': {
          'type': 'object',
          'properties': {
            ..._metadata,
            'add_fields': {
              'type': 'array',
              'items': _newField,
              'minItems': 1,
              'maxItems': 100,
            },
            'update_fields': {
              'type': 'array',
              'minItems': 1,
              'maxItems': 100,
              'items': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'string'},
                  ..._fieldProperties,
                },
                'required': ['id'],
                'minProperties': 2,
                'additionalProperties': false,
              },
            },
            'remove_field_ids': {
              'type': 'array',
              'items': {'type': 'string'},
              'minItems': 1,
              'maxItems': 100,
              'uniqueItems': true,
            },
          },
          'additionalProperties': false,
          'minProperties': 1,
        },
      },
      required: ['table_id', 'expected_table_version', 'patch'],
    ),
  ];

  static Never _invalid() => throw const AgentFailure(AgentFailureCode.invalid);

  static List<Object?> _list(Object? value) {
    if (value is! List || value.isEmpty || value.length > 100) _invalid();
    return value;
  }

  static List<JsonObject> _newFields(Object? raw, String suffix) {
    final fields = _list(raw);
    return [
      for (var i = 0; i < fields.length; i++)
        _newFieldData(fields[i], 'f_${suffix}_$i'),
    ];
  }

  static JsonObject _newFieldData(Object? raw, String id) {
    if (raw is! JsonObject) _invalid();
    requireToolKeys(
      raw,
      {..._fieldProperties.keys, 'type', 'scale'},
      required: {'name', 'type'},
    );
    return {'id': id, ...raw};
  }

  static JsonObject prepare({
    required String name,
    required JsonObject args,
    required String callId,
    required String suffix,
    required WorkspaceSnapshot snapshot,
    required DateTime now,
  }) {
    final create = name == 'data_table_create';
    if (!names.contains(name)) _invalid();
    requireToolKeys(
      args,
      create
          ? {'name', 'description', 'fields'}
          : {'table_id', 'expected_table_version', 'patch'},
      required: create
          ? {'name', 'fields'}
          : {'table_id', 'expected_table_version', 'patch'},
    );
    if (!create && args['expected_table_version'] == null) _invalid();
    final before = create
        ? null
        : BusinessQueries.table(
            snapshot,
            args['table_id'],
            args['expected_table_version'],
          );
    final id = before?.id ?? 'bt_$suffix';
    if (create && snapshot.find(WorkspaceEntityKind.dataTable, id) != null) {
      throw const WorkspaceFailure(WorkspaceFailureCode.versionConflict);
    }
    final patch = create ? args : args['patch'];
    if (patch is! JsonObject || patch.isEmpty) _invalid();
    final fields = create
        ? _newFields(args['fields'], suffix)
        : _editedFields(before!, patch, suffix);
    final values = {
      for (final key in _metadata.keys)
        if (patch.containsKey(key)) key: patch[key],
      'fields': fields,
    };
    // Use the same canonical validation as manual table editing before deciding
    // whether the structural revision changes (a no-op patch keeps its revision).
    final normalized = applyBusinessPatch(WorkspaceEntityKind.dataTable, null, {
      'name': before?.data['name'] ?? args['name'],
      ...values,
    });
    final changed =
        before != null &&
        canonicalWorkspaceJson(before.data['fields']) !=
            canonicalWorkspaceJson(normalized['fields']);
    final after = applyBusinessPatch(
      WorkspaceEntityKind.dataTable,
      before?.data,
      {
        ...values,
        'fields': normalized['fields'],
        'schema_version':
            (before?.data['schema_version'] as int? ?? 1) + (changed ? 1 : 0),
      },
    );
    return immutableJson({
      'tool_call_id': callId,
      'name': name,
      'operation': create ? 'create' : 'edit',
      'before': before?.toJson(),
      'after': after,
      'requires_review': true,
      'table_intent': {'args': args, 'suffix': suffix},
      'mutation': WorkspaceMutation(
        actionId: 'ta_$suffix',
        kind: WorkspaceEntityKind.dataTable,
        entityId: id,
        mutation: create
            ? WorkspaceMutationKind.create
            : WorkspaceMutationKind.update,
        expectedVersion: before?.version,
        patch: {...after}..remove('retired_field_ids'),
      ).toJson(),
    });
  }

  static List<JsonObject> _editedFields(
    WorkspaceEntity table,
    JsonObject patch,
    String suffix,
  ) {
    requireToolKeys(patch, {
      ..._metadata.keys,
      'add_fields',
      'update_fields',
      'remove_field_ids',
    });
    final fields = BusinessQueries.fields(table).map((f) => {...f}).toList();
    final used = <String>{};
    if (patch.containsKey('update_fields')) {
      for (final raw in _list(patch['update_fields'])) {
        if (raw is! JsonObject || raw.length < 2) _invalid();
        requireToolKeys(
          raw,
          {'id', ..._fieldProperties.keys},
          required: {'id'},
        );
        final id = BusinessQueries.id(raw['id']);
        final index = fields.indexWhere((f) => f['id'] == id);
        if (index < 0 || !used.add(id)) _invalid();
        fields[index] = {...fields[index], ...raw};
      }
    }
    if (patch.containsKey('remove_field_ids')) {
      for (final raw in _list(patch['remove_field_ids'])) {
        final id = BusinessQueries.id(raw);
        if (!used.add(id) || !fields.any((f) => f['id'] == id)) _invalid();
        fields.removeWhere((f) => f['id'] == id);
      }
    }
    if (patch.containsKey('add_fields')) {
      fields.addAll(_newFields(patch['add_fields'], suffix));
    }
    return fields;
  }

  static JsonObject refresh(
    JsonObject call,
    WorkspaceSnapshot snapshot,
    DateTime now,
  ) {
    final intent = call['table_intent']! as JsonObject;
    final args = intent['args']! as JsonObject;
    return prepare(
      name: call['name']! as String,
      args: {
        ...args,
        if (call['name'] == 'data_table_update')
          'expected_table_version': BusinessQueries.table(
            snapshot,
            args['table_id'],
            null,
          ).version,
      },
      callId: call['tool_call_id']! as String,
      suffix: intent['suffix']! as String,
      snapshot: snapshot,
      now: now,
    );
  }
}
