import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/recurrence_commands.dart';
import '../workspace_actions.dart';
import '../widgets/app_button.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_toast.dart';
import '../../domain/models/todo.dart';
import '../../domain/recurrence/recurrence_schedule.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'todo_utils.dart';

/// A completed status is always a single-instance operation. Other changes to a
/// linked task are planned before scope confirmation and submitted unchanged.
Future<bool> saveTodoEdit(
  BuildContext context,
  WidgetRef ref,
  Todo before,
  Todo after, {
  bool repeatSettings = false,
}) async {
  final service = ref.read(recurrenceCommandsProvider);
  if (service != null &&
      before.seriesId != null &&
      !service.hasChanges(before, after)) {
    return true;
  }
  if (service == null ||
      (before.seriesId == null &&
          (!repeatSettings || after.repeatRule == null)) ||
      before.status != after.status) {
    return await workspaceUi(context, () async {
          await ref.read(workspaceUiCommandsProvider).updateTodo(after);
          return true;
        }) ??
        false;
  }
  if (before.seriesId == null && before.dueAt == null) {
    AppToast.show(context, message: '请先设置本次截止日期，再开启重复');
    return false;
  }
  final release = service.session.holdAutomaticWork();
  try {
    final proposal = await workspaceUi(
      context,
      () async => before.seriesId == null
          ? service.startProposal(
              before,
              after.repeatRule!,
              after.repeatTimezone!,
            )
          : service.editProposal(before, after),
    );
    if (proposal == null || !context.mounted) return false;
    return await _showProposal(context, service, proposal);
  } finally {
    release();
  }
}

Future<bool> deleteRecurringTodo(
  BuildContext context,
  WidgetRef ref,
  Todo todo,
) async {
  final service = ref.read(recurrenceCommandsProvider);
  if (service == null) return false;
  final release = service.session.holdAutomaticWork();
  try {
    final proposal = await workspaceUi(
      context,
      () async => service.deleteProposal(todo),
    );
    if (proposal == null || !context.mounted) return false;
    return await _showProposal(context, service, proposal);
  } finally {
    release();
  }
}

Future<bool> _showProposal(
  BuildContext context,
  RecurrenceCommands service,
  RecurrenceProposal proposal,
) async {
  final report = AppToast.presenter(context);
  AppToast.dismiss();
  final change = await AppSheet.show<UiWorkspaceChange<WorkspaceReceipt>>(
    context,
    dismissible: false,
    child: RecurrenceActionSheet(service: service, proposal: proposal),
  );
  if (change == null) return false;
  if (context.mounted) {
    AppToast.show(
      context,
      message: proposal.deleting ? '已删除所选范围' : '重复待办已更新',
      actionLabel: '撤销',
      duration: const Duration(seconds: 10),
      onAction: () async {
        try {
          await change.undo();
          report('已撤销');
        } catch (error) {
          report(workspaceErrorMessage(error));
        }
      },
    );
  }
  return true;
}

class RecurrenceActionSheet extends StatefulWidget {
  const RecurrenceActionSheet({
    super.key,
    required this.service,
    required this.proposal,
  });
  final RecurrenceCommands service;
  final RecurrenceProposal proposal;
  @override
  State<RecurrenceActionSheet> createState() => _RecurrenceActionSheetState();
}

class _RecurrenceActionSheetState extends State<RecurrenceActionSheet> {
  int _selected = 0;
  bool _saving = false;
  bool _conflict = false;
  bool _showAll = false;
  String? _error;

  Future<void> _submit() async {
    if (_saving || _conflict) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.service.execute(
        widget.proposal.choices[_selected].command,
      );
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _conflict =
              error is WorkspaceFailure &&
              error.code == WorkspaceFailureCode.versionConflict;
          _error = error is RecurrenceCoverageException
              ? '日期超出当前时区数据范围，请缩短结束时间'
              : workspaceErrorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final proposal = widget.proposal;
    final choice = proposal.choices[_selected];
    return PopScope(
      canPop: !_saving,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                proposal.title,
                style: AppTextStyles.title2.copyWith(color: c.labelPrimary),
              ),
              const SizedBox(height: 12),
              for (final (index, option) in proposal.choices.indexed) ...[
                AppButton(
                  label: option.label,
                  expand: true,
                  type: index == _selected
                      ? AppButtonType.primary
                      : AppButtonType.secondary,
                  enabled: !_saving && !_conflict,
                  onPressed: () => setState(() {
                    _selected = index;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                choice.future
                    ? '将更新所选范围的重复安排，保留此前记录和其他已完成任务。'
                    : '只处理这一次，其他日期和重复安排保持不变。',
                style: AppTextStyles.callout.copyWith(color: c.labelSecondary),
              ),
              const SizedBox(height: 12),
              for (final note in proposal.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    note,
                    style: AppTextStyles.callout.copyWith(
                      color: c.labelSecondary,
                    ),
                  ),
                ),
              Text(
                '本次变更：新增 ${choice.count(WorkspaceMutationKind.create)} 修改 ${choice.count(WorkspaceMutationKind.update)} 删除 ${choice.count(WorkspaceMutationKind.delete)}',
                style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
              ),
              const SizedBox(height: 8),
              for (final item in choice.changes.take(
                _showAll ? choice.changes.length : 3,
              ))
                _ChangeRow(change: item),
              if (choice.changes.length > 3)
                AppButton(
                  label: _showAll
                      ? '收起记录'
                      : '查看全部 ${choice.changes.length} 条记录',
                  type: AppButtonType.ghost,
                  onPressed: () => setState(() => _showAll = !_showAll),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: AppTextStyles.callout.copyWith(
                      color: c.labelPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: proposal.deleting ? '确认删除' : '确认修改',
                expand: true,
                type: proposal.deleting
                    ? AppButtonType.destructive
                    : AppButtonType.primary,
                enabled: !_conflict,
                loading: _saving,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: '取消',
                type: AppButtonType.secondary,
                expand: true,
                enabled: !_saving,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change});
  final RecurrenceChange change;
  String _value(
    String field,
    Map<String, Object?>? data, {
    bool before = false,
  }) {
    final value = data?[field];
    if (value == null) return '无';
    return switch (field) {
      'category_id' =>
        (before ? change.beforeCategory : change.afterCategory) ?? '未分类',
      'priority' => TodoPriority.values.byName(value as String).label,
      'repeat_rule' => repeatLabelOf(value as String),
      'tags' => (value as List).isEmpty ? '无' : value.join('、'),
      'remind_rules' =>
        (value as List).isEmpty
            ? '关闭'
            : value
                  .map((r) {
                    final row = r as Map;
                    return remindRuleLabel(
                      RemindRule(
                        id: row['id'] as String,
                        offsetMinutes: row['offset_minutes'] as int?,
                        absoluteAt: row['absolute_at'] == null
                            ? null
                            : DateTime.parse(row['absolute_at'] as String)
                                  .toLocal(),
                      ),
                    );
                  })
                  .join('、'),
      _ => value.toString(),
    };
  }

  String _summary(Map<String, Object?>? data) {
    if (data == null) return '';
    final due = data['due_at'] as String?;
    final date = due == null ? null : DateTime.parse(due).toLocal();
    final when = date == null
        ? '无截止'
        : '${date.year}/${date.month}/${date.day} '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${data['title']} $when';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final label = switch (change.kind) {
      WorkspaceMutationKind.create => '新增',
      WorkspaceMutationKind.update => '修改',
      WorkspaceMutationKind.delete => '删除',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$label ${_summary(change.after ?? change.before)}',
            style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
          ),
          if (change.kind == WorkspaceMutationKind.update &&
              _summary(change.before) != _summary(change.after))
            Text(
              '原：${_summary(change.before)}',
              style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
            ),
          if (change.after != null)
            for (final field in const {
              'note': '备注',
              'priority': '优先级',
              'category_id': '分类',
              'tags': '标签',
              'remind_rules': '提醒',
              'repeat_rule': '重复',
              'repeat_timezone': '时区',
            }.entries)
              if (canonicalWorkspaceJson(change.before?[field.key]) !=
                      canonicalWorkspaceJson(change.after?[field.key]) &&
                  (change.kind == WorkspaceMutationKind.update ||
                      field.key == 'repeat_rule'))
                Text(
                  '${field.value}：${change.before == null ? '' : '${_value(field.key, change.before, before: true)} → '}${_value(field.key, change.after)}',
                  style: AppTextStyles.caption.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
        ],
      ),
    );
  }
}
