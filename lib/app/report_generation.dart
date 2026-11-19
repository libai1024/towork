import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../agent/agent_prompt.dart';
import '../data/local/app_database.dart';
import '../data/local/report_snapshot_builder.dart';
import '../data/local/report_store.dart';
import '../data/local/workspace_command_store.dart';
import '../domain/ai/model_gateway.dart';
import '../domain/recurrence/recurrence_schedule.dart';
import '../domain/reports/report_documents.dart';
import '../domain/settings/model_settings_service.dart';
import 'model_settings_provider.dart';
import 'local_database_provider.dart';
import 'local_workspace_session.dart';

/// Creates report snapshots for calendar periods in a user timezone, and
/// writes AI summaries on explicit user action only (Code subscription rule:
/// no background model calls). Numbers always come from the frozen snapshot.
class ReportGenerationService {
  ReportGenerationService(
    this._db,
    ModelSettingsService settings, {
    ModelGateway? gateway,
    DateTime Function()? clock,
  }) : _settings = settings,
       _gateway = gateway ?? settings.gateway,
       _clock = clock ?? DateTime.now;
  final AppDatabase _db;
  final ModelSettingsService _settings;
  final ModelGateway _gateway;
  final DateTime Function() _clock;

  ({int startAt, int endAt, int previousStartAt}) _bounds(
    ReportPeriodKind kind,
    String timezone,
  ) {
    final location = RecurrenceTimeZones.location(timezone);
    final now = tz.TZDateTime.from(_clock().toUtc(), location);
    tz.TZDateTime start;
    tz.TZDateTime end;
    tz.TZDateTime previous;
    switch (kind) {
      case ReportPeriodKind.weekly:
        // Weeks start Monday 00:00 in the report timezone.
        final daysFromMonday = now.weekday - 1;
        final monday = tz.TZDateTime(
          location,
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: daysFromMonday));
        start = monday;
        end = start.add(const Duration(days: 7));
        previous = start.subtract(const Duration(days: 7));
      case ReportPeriodKind.monthly:
        start = tz.TZDateTime(location, now.year, now.month);
        final firstNext = start.month == 12
            ? tz.TZDateTime(location, now.year + 1, 1)
            : tz.TZDateTime(location, now.year, now.month + 1);
        end = firstNext;
        previous = start.month == 1
            ? tz.TZDateTime(location, now.year - 1, 12)
            : tz.TZDateTime(location, now.year, start.month - 1);
      case ReportPeriodKind.custom:
        throw const FormatException(
          'custom period bounds come from the caller',
        );
    }
    return (
      startAt: start.toUtc().microsecondsSinceEpoch,
      endAt: end.toUtc().microsecondsSinceEpoch,
      previousStartAt: previous.toUtc().microsecondsSinceEpoch,
    );
  }

  String _documentId(ReportPeriodKind kind, int startAt) =>
      'report_${kind.name}_$startAt';

  /// Idempotent per period: regenerating the same period returns the stored
  /// document untouched instead of re-snapshotting.
  Future<ReportDocument> generate({
    required ReportPeriodKind kind,
    required String timezone,
    Set<String>? categoryIds,
  }) async {
    final bounds = _bounds(kind, timezone);
    final store = SqliteReportStore(_db);
    final id = _documentId(kind, bounds.startAt);
    final existing = await store.read(id);
    if (existing != null) return existing;

    final snapshot = await SqliteWorkspaceCommandStore(_db).load();
    final profile = await _db.loadOrCreateProfile();
    final dataRows = snapshot.dataRows.toList();
    final categories =
        categoryIds ?? snapshot.categories.map((c) => c.id).toSet();
    var rowsCreated = 0;
    for (final row in dataRows) {
      final created = row.createdAt.toUtc().microsecondsSinceEpoch;
      if (created >= bounds.startAt && created < bounds.endAt) rowsCreated++;
    }
    final metrics = ReportSnapshotBuilder.build(
      snapshot: snapshot,
      nickname: profile.nickname,
      startAt: bounds.startAt,
      endAt: bounds.endAt,
      previousStartAt: bounds.previousStartAt,
      categoryIds: categories,
      dataRowsTotal: dataRows.length,
      dataRowsCreated: rowsCreated,
    );
    final snapshotJson = {
      'schema_version': 1,
      'period': {
        'start': DateTime.fromMicrosecondsSinceEpoch(
          bounds.startAt,
          isUtc: true,
        ).toIso8601String(),
        'end_exclusive': DateTime.fromMicrosecondsSinceEpoch(
          bounds.endAt,
          isUtc: true,
        ).toIso8601String(),
        'timezone': timezone,
      },
      'metrics': metrics.toJson(),
    };
    return store.create(
      ReportDocument(
        id: id,
        kind: kind,
        startAt: bounds.startAt,
        endAt: bounds.endAt,
        timezone: timezone,
        metrics: metrics,
        status: ReportDocumentStatus.snapshotReady,
        snapshotId: reportSnapshotId(snapshotJson),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  }

  /// User-initiated summary. The model writes prose only; every number it may
  /// quote rides in the prompt from the frozen snapshot. A successful summary
  /// is never re-billed by reruns (regenerate only after failure/explicit ask).
  Future<ReportDocument> summarize(ReportDocument document) async {
    if (document.summary != null) return document;
    final credential = await _settings.runtimeCredential();
    final store = SqliteReportStore(_db);
    try {
      final completion = await _collect(
        ModelRequest(
          profile: credential.configuration.profile,
          messages: [
            {
              'role': 'system',
              'content':
                  '你是周报/月报的总结撰写者。下面 JSON 里的数字来自本地统计快照，是唯一事实：'
                  '只能引用给出的数字，不得编造、推算或补充任何新数字；没有数据就说明本周没有记录。'
                  '输出中文，仅写有依据的进展、问题和必要动作，最多 240 字，不凑段落，不输出 JSON。'
                  '${AgentPrompt.responseStyle}',
            },
            {
              'role': 'user',
              'content': jsonEncode(
                document.metrics.toJson(),
                toEncodable: (o) => o.toString(),
              ),
            },
          ],
          maxTokens: 1024,
        ),
        credential.secret,
      );
      return await store.saveSummary(document.id, summary: completion);
    } on Object {
      await store.markFailed(document.id);
      rethrow;
    }
  }

  Future<String> _collect(ModelRequest request, String apiKey) async {
    final buffer = StringBuffer();
    await for (final event in _gateway.stream(request, apiKey: apiKey)) {
      if (event is ModelTextDelta) {
        buffer.write(event.text);
      } else if (event is ModelCompleted) {
        if (event.finishReason != 'stop' ||
            event.text.trim().isEmpty && buffer.isEmpty) {
          throw const ModelFailure(ModelFailureCode.protocol);
        }
        if (buffer.isEmpty) return event.text;
      }
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    return text;
  }
}

final reportGenerationProvider = FutureProvider<ReportGenerationService?>((
  ref,
) async {
  final session = ref.watch(localWorkspaceSessionProvider);
  if (session == null) return null;
  final db = await ref.watch(localDatabaseProvider.future);
  final settings = await ref.watch(modelSettingsServiceProvider.future);
  return ReportGenerationService(db, settings);
});
