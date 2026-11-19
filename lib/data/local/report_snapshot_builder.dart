import '../../domain/reports/report_documents.dart';
import '../../domain/workspace/workspace_commands.dart';

/// Builds the frozen metrics of one report period from a committed workspace
/// snapshot. Window checks are UTC instant comparisons on [startAt, endAt).
///
/// 口径 (frozen, FC5):
/// - created: todo created_at falls in the window (all statuses, instances
///   of recurring series count as todos).
/// - completed: status done AND completed_at in window. Cancelled never counts.
/// - completion denominator: completed_in_window + still-open at end (pending
///   or inProgress, created before end). The rate always stores its own
///   numerator/denominator/label so no later view re-derives it.
/// - overdue at end: open at end with due_at before endAt.
/// - previous window metrics are computed identically for deltas.
class ReportSnapshotBuilder {
  const ReportSnapshotBuilder._();

  static const _rateLabel = '完成数 ÷（周期内完成 + 期末仍未完成且未取消）；重复待办按已生成实例计；取消不计完成';

  static bool _inWindow(DateTime? time, int startAt, int endAt) {
    if (time == null) return false;
    final micros = time.toUtc().microsecondsSinceEpoch;
    return micros >= startAt && micros < endAt;
  }

  static bool _openAtEnd(WorkspaceEntity todo, int endAt) {
    if (todo.isDeleted) return false;
    if (todo.createdAt.toUtc().microsecondsSinceEpoch >= endAt) return false;
    final status = todo.data['status']! as String;
    return status == 'pending' || status == 'inProgress';
  }

  static ({int completed, ReportRate rate}) _core(
    Iterable<WorkspaceEntity> todos,
    int startAt,
    int endAt, {
    Map<String, (int created, int completed)>? byCategory,
  }) {
    var completed = 0;
    var openAtEnd = 0;
    for (final todo in todos) {
      final status = todo.data['status']! as String;
      final done =
          status == 'done' &&
          _inWindow(_parse(todo.data['completed_at']), startAt, endAt);
      if (done) completed++;
      final open = _openAtEnd(todo, endAt);
      if (open) openAtEnd++;
      if (byCategory != null) {
        final key = todo.data['category_id'] as String? ?? '';
        final entry = byCategory[key] ?? (0, 0);
        final createdInWindow = _inWindow(todo.createdAt, startAt, endAt);
        if (createdInWindow || done) {
          // Apply both increments from one base; sequential writes would
          // overwrite each other for todos created and done in one window.
          byCategory[key] = (
            entry.$1 + (createdInWindow ? 1 : 0),
            entry.$2 + (done ? 1 : 0),
          );
        }
      }
    }
    return (
      completed: completed,
      rate: ReportRate(
        numerator: completed,
        denominator: completed + openAtEnd,
        label: _rateLabel,
      ),
    );
  }

  static DateTime? _parse(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  static ReportMetrics build({
    required WorkspaceSnapshot snapshot,
    required String nickname,
    required int startAt,
    required int endAt,
    required int previousStartAt,
    required Iterable<String> categoryIds,
    int dataRowsTotal = 0,
    int dataRowsCreated = 0,
  }) {
    final todos = snapshot.todos;
    var created = 0;
    var cancelledInWindow = 0;
    for (final todo in todos) {
      if (_inWindow(todo.createdAt, startAt, endAt)) created++;
      if (todo.data['status'] == 'cancelled' &&
          _inWindow(todo.updatedAt, startAt, endAt)) {
        cancelledInWindow++;
      }
    }
    final byCategoryRaw = <String, (int created, int completed)>{};
    final core = _core(todos, startAt, endAt, byCategory: byCategoryRaw);
    final previous = _core(todos, previousStartAt, startAt);

    final categories = {
      for (final entity in snapshot.categories)
        entity.id: (
          entity.data['name']! as String,
          entity.data['color_value']! as int,
        ),
    };
    final byCategory = <ReportCategoryMetric>[
      for (final id in categoryIds)
        if (categories.containsKey(id))
          ReportCategoryMetric(
            id: id,
            name: categories[id]!.$1,
            colorValue: categories[id]!.$2,
            created: byCategoryRaw[id]?.$1 ?? 0,
            completed: byCategoryRaw[id]?.$2 ?? 0,
          ),
      if (categoryIds.contains('') || byCategoryRaw.containsKey(''))
        ReportCategoryMetric(
          id: '',
          name: '未分类',
          colorValue: 0xff808080,
          created: byCategoryRaw['']?.$1 ?? 0,
          completed: byCategoryRaw['']?.$2 ?? 0,
        ),
    ]..sort((a, b) => b.completed.compareTo(a.completed));

    var openAtEnd = 0;
    var overdueAtEnd = 0;
    for (final todo in todos) {
      if (_openAtEnd(todo, endAt)) {
        openAtEnd++;
        final due = _parse(todo.data['due_at']);
        final micros = due?.toUtc().microsecondsSinceEpoch;
        if (micros != null && micros < endAt) overdueAtEnd++;
      }
    }

    return ReportMetrics(
      created: created,
      completed: core.completed,
      cancelledInWindow: cancelledInWindow,
      openAtEnd: openAtEnd,
      overdueAtEnd: overdueAtEnd,
      completion: core.rate,
      byCategory: byCategory,
      previousCompleted: previous.completed,
      previousCompletion: previous.rate,
      dataRowsTotal: dataRowsTotal,
      dataRowsCreated: dataRowsCreated,
      nickname: nickname,
    );
  }
}
