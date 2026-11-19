import '../ai/provider_catalog.dart';

import 'todo_step.dart';
export 'todo_step.dart';

enum TodoStatus { pending, inProgress, done, cancelled }

enum TodoPriority { none, low, medium, high, urgent }

enum TodoSource { ai, manual }

class Todo {
  Todo({
    required this.id,
    this.version = 0,
    required this.title,
    this.note,
    this.status = TodoStatus.pending,
    this.priority = TodoPriority.none,
    this.dueAt,
    this.remindAt,
    List<RemindRule> remindRules = const [],
    this.repeatRule,
    this.repeatTimezone,
    this.seriesId,
    this.occurrenceKey,
    this.occurrenceIndex,
    this.occurrenceAt,
    this.categoryId,
    this.source = TodoSource.manual,
    this.sourceMessageId,
    this.sourceModel,
    this.sourceProvider,
    List<TodoStep> steps = const [],
    List<String> tags = const [],
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  }) : steps = List.unmodifiable(steps),
       remindRules = List<RemindRule>.unmodifiable(remindRules),
       tags = List<String>.unmodifiable(tags);

  final String id;
  final int version;
  final String title;
  final String? note;
  final TodoStatus status;
  final TodoPriority priority;
  final DateTime? dueAt;
  final DateTime? remindAt;

  /// 提醒多规则（03-todo-detail.md §5.3）：offsetMinutes 相对截止 / absoluteAt 绝对时间。
  final List<RemindRule> remindRules;

  /// RRULE 字符串（用户不可见，详情页可视化编辑器双向映射）。
  final String? repeatRule;

  /// Fixed IANA timezone. Null means a legacy rule has not selected a zone.
  final String? repeatTimezone;
  final String? seriesId;

  /// Original civil slot; changing dueAt never changes this identity.
  final String? occurrenceKey;
  final int? occurrenceIndex;
  final DateTime? occurrenceAt;
  final String? categoryId;
  final TodoSource source;
  final String? sourceMessageId;

  /// 生成此待办的模型标识（如 kimi-for-coding / deepseek-flash）；仅展示用元数据。
  final String? sourceModel;
  final ProviderKind? sourceProvider;
  final List<TodoStep> steps;
  int get completedSteps => steps.where((s) => s.done).length;
  String get stepProgress => '步骤 $completedSteps/${steps.length}';
  final List<String> tags;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  bool get isActive =>
      status == TodoStatus.pending || status == TodoStatus.inProgress;

  bool isOverdue(DateTime now) =>
      isActive && dueAt != null && dueAt!.isBefore(now);

  Todo copyWith({
    String? title,
    Object? note = _keep,
    TodoStatus? status,
    TodoPriority? priority,
    Object? dueAt = _keep,
    Object? remindAt = _keep,
    List<RemindRule>? remindRules,
    Object? repeatRule = _keep,
    Object? repeatTimezone = _keep,
    Object? categoryId = _keep,
    Object? sourceMessageId = _keep,
    List<TodoStep>? steps,
    List<String>? tags,
    int? sortOrder,
    Object? updatedAt = _keep,
    Object? completedAt = _keep,
  }) {
    return Todo(
      id: id,
      version: version,
      title: title ?? this.title,
      note: identical(note, _keep) ? this.note : note as String?,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueAt: identical(dueAt, _keep) ? this.dueAt : dueAt as DateTime?,
      remindAt: identical(remindAt, _keep)
          ? this.remindAt
          : remindAt as DateTime?,
      remindRules: remindRules ?? this.remindRules,
      repeatRule: identical(repeatRule, _keep)
          ? this.repeatRule
          : repeatRule as String?,
      repeatTimezone: identical(repeatTimezone, _keep)
          ? this.repeatTimezone
          : repeatTimezone as String?,
      seriesId: seriesId,
      occurrenceKey: occurrenceKey,
      occurrenceIndex: occurrenceIndex,
      occurrenceAt: occurrenceAt,
      categoryId: identical(categoryId, _keep)
          ? this.categoryId
          : categoryId as String?,
      source: source,
      sourceModel: sourceModel,
      sourceProvider: sourceProvider,
      sourceMessageId: identical(sourceMessageId, _keep)
          ? this.sourceMessageId
          : sourceMessageId as String?,
      steps: steps ?? this.steps,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: identical(updatedAt, _keep)
          ? this.updatedAt
          : updatedAt as DateTime?,
      completedAt: identical(completedAt, _keep)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }
}

/// copyWith 的空值守卫：区分「不传（保持原值）」与「显式置 null（清除）」。
const Object _keep = Object();

/// 提醒规则（03-todo-detail.md §8）：相对截止 offsetMinutes（0 = 截止时）
/// 或绝对时间 absoluteAt，二者居一。
class RemindRule {
  const RemindRule({required this.id, this.offsetMinutes, this.absoluteAt})
    : assert(
        (offsetMinutes == null) != (absoluteAt == null),
        'A reminder needs either an offset or an absolute time, never both.',
      );

  final String id;
  final int? offsetMinutes;
  final DateTime? absoluteAt;
}
