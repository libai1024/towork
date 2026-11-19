import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../workspace/workspace_commands.dart';

/// Frozen report statistics (FC5). Every rate carries its exact numerator and
/// denominator; recurring materialized instances count as todos; cancelled is
/// never completion. All window checks are UTC instant comparisons — the
/// caller derives period bounds from the user's calendar timezone.
enum ReportDocumentStatus { snapshotReady, summaryReady, failed }

enum ReportPeriodKind { weekly, monthly, custom }

class ReportRate {
  const ReportRate({
    required this.numerator,
    required this.denominator,
    required this.label,
  });
  final int numerator, denominator;

  /// 口径 in one sentence, stored so later UI never guesses the formula.
  final String label;
  double? get value => denominator == 0 ? null : numerator * 100 / denominator;

  Map<String, Object?> toJson() => {
    'numerator': numerator,
    'denominator': denominator,
    'label': label,
  };
  factory ReportRate.fromJson(Map<String, Object?> json) => ReportRate(
    numerator: json['numerator']! as int,
    denominator: json['denominator']! as int,
    label: json['label']! as String,
  );
}

class ReportCategoryMetric {
  const ReportCategoryMetric({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.created,
    required this.completed,
  });
  final String id, name;
  final int colorValue, created, completed;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'color_value': colorValue,
    'created': created,
    'completed': completed,
  };
  factory ReportCategoryMetric.fromJson(Map<String, Object?> json) =>
      ReportCategoryMetric(
        id: json['id']! as String,
        name: json['name']! as String,
        colorValue: json['color_value']! as int,
        created: json['created']! as int,
        completed: json['completed']! as int,
      );
}

class ReportMetrics {
  const ReportMetrics({
    required this.created,
    required this.completed,
    required this.cancelledInWindow,
    required this.openAtEnd,
    required this.overdueAtEnd,
    required this.completion,
    required this.byCategory,
    this.previousCompleted,
    this.previousCompletion,
    required this.dataRowsTotal,
    required this.dataRowsCreated,
    required this.nickname,
  });
  final int created, completed, cancelledInWindow, openAtEnd, overdueAtEnd;
  final ReportRate completion;
  final List<ReportCategoryMetric> byCategory;
  final int? previousCompleted;
  final ReportRate? previousCompletion;
  final int dataRowsTotal, dataRowsCreated;
  final String nickname;

  Map<String, Object?> toJson() => {
    'created': created,
    'completed': completed,
    'cancelled_in_window': cancelledInWindow,
    'open_at_end': openAtEnd,
    'overdue_at_end': overdueAtEnd,
    'completion': completion.toJson(),
    'by_category': [for (final c in byCategory) c.toJson()],
    if (previousCompleted != null) 'previous_completed': previousCompleted,
    if (previousCompletion != null)
      'previous_completion': previousCompletion!.toJson(),
    'data_rows_total': dataRowsTotal,
    'data_rows_created': dataRowsCreated,
    'nickname': nickname,
  };
  factory ReportMetrics.fromJson(Map<String, Object?> json) => ReportMetrics(
    created: json['created']! as int,
    completed: json['completed']! as int,
    cancelledInWindow: json['cancelled_in_window']! as int,
    openAtEnd: json['open_at_end']! as int,
    overdueAtEnd: json['overdue_at_end']! as int,
    completion: ReportRate.fromJson(
      (json['completion']! as Map).cast<String, Object?>(),
    ),
    byCategory: [
      for (final raw in json['by_category']! as List)
        ReportCategoryMetric.fromJson((raw as Map).cast<String, Object?>()),
    ],
    previousCompleted: json['previous_completed'] as int?,
    previousCompletion: json['previous_completion'] == null
        ? null
        : ReportRate.fromJson(
            (json['previous_completion']! as Map).cast<String, Object?>(),
          ),
    dataRowsTotal: json['data_rows_total']! as int,
    dataRowsCreated: json['data_rows_created']! as int,
    nickname: json['nickname']! as String,
  );
}

/// The immutable artifact: an archived report never rewrites when nicknames
/// or categories are renamed later, because refs live inside the snapshot.
class ReportDocument {
  const ReportDocument({
    required this.id,
    required this.kind,
    required this.startAt,
    required this.endAt,
    required this.timezone,
    required this.metrics,
    required this.status,
    this.summary,
    this.templateId,
    required this.snapshotId,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id, timezone, snapshotId;
  final ReportPeriodKind kind;
  final ReportDocumentStatus status;
  final int startAt, endAt, createdAt, updatedAt;
  final ReportMetrics metrics;
  final String? summary, templateId;
  bool get endExclusive => true;

  /// Digest input: deliberately excludes any snapshot_id field so the id is
  /// a pure function of the frozen content.
  Map<String, Object?> snapshotJson() => {
    'schema_version': 1,
    'period': {
      'start': DateTime.fromMicrosecondsSinceEpoch(
        startAt,
        isUtc: true,
      ).toIso8601String(),
      'end_exclusive': DateTime.fromMicrosecondsSinceEpoch(
        endAt,
        isUtc: true,
      ).toIso8601String(),
      'timezone': timezone,
    },
    'metrics': metrics.toJson(),
  };
}

abstract interface class ReportDocumentStore {
  Future<ReportDocument> create(ReportDocument document);
  Future<ReportDocument?> read(String id);
  Future<List<ReportDocument>> list({bool newestFirst});
  Future<ReportDocument> saveSummary(
    String id, {
    required String summary,
    String? templateId,
  });
  Future<ReportDocument> markFailed(String id);
}

/// Deterministic snapshot digest over the frozen payload.
String reportSnapshotId(Map<String, Object?> snapshotJson) => sha256
    .convert(utf8.encode(canonicalWorkspaceJson(snapshotJson)))
    .toString();
