import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/ai/model_gateway.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../theme/app_text_styles.dart';
import '../todo/todo_utils.dart';
import 'agent_table_preview.dart';

/// 审批卡里一组提醒规则的读法：「准时、提前 30 分钟、11-15 14:30」。
String reminderRulesLabel(Object? value) {
  if (value is! List || value.isEmpty) return '无';
  return value
      .map((rule) {
        if (rule is! Map) return '提醒';
        final offset = rule['offset_minutes'];
        if (offset is int) {
          if (offset == 0) return '准时';
          if (offset % 1440 == 0) return '提前 ${offset ~/ 1440} 天';
          if (offset % 60 == 0) return '提前 ${offset ~/ 60} 小时';
          return '提前 $offset 分钟';
        }
        final at = rule['absolute_at'];
        final date = at is String ? DateTime.tryParse(at) : null;
        return date == null
            ? '提醒'
            : DateFormat('MM-dd HH:mm').format(date.toLocal());
      })
      .join('、');
}

class AgentChangePreview extends ConsumerWidget {
  const AgentChangePreview({super.key, required this.change});
  final JsonObject change;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (change['table_intent'] != null) {
      return AgentTablePreview(change: change);
    }
    final categories = {
      for (final c in ref.watch(categoryListProvider)) c.id: c.name,
    };
    final before = ((change['before'] as Map?)?['data'] as Map?) ?? {};
    final after = (change['after'] as Map?) ?? {};
    final operation = switch (change['operation']) {
      'create' => '新增',
      'edit' => '编辑',
      'complete' => '完成',
      'delete' => '删除',
      _ => '修改',
    };
    final table = change['business_table'];
    if (table is JsonObject) {
      final oldValues = (before['values'] as Map?) ?? {};
      final newValues = (after['values'] as Map?) ?? {};
      String cell(Map<Object?, Object?> values, String id) =>
          !values.containsKey(id)
          ? '未填写'
          : values[id] == null
          ? '已清空'
          : values[id] == true
          ? '是'
          : values[id] == false
          ? '否'
          : values[id].toString();
      final rowId = (change['mutation']! as Map)['entity_id'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$operation ${table['name']}', style: AppTextStyles.subhead),
            Text('记录 $rowId', style: AppTextStyles.caption),
            if ((change['uncertain_field_ids'] as List?)?.isNotEmpty == true)
              Text('图片识别存在不确定字段，请对照原图核对后确认。', style: AppTextStyles.footnote),
            for (final field in (table['fields']! as List).cast<JsonObject>())
              if (cell(oldValues, field['id']! as String) !=
                  cell(newValues, field['id']! as String))
                SelectableText(
                  '${field['name']}${field['unit'] == null ? '' : '（${field['unit']}）'}：${cell(oldValues, field['id']! as String)} → ${cell(newValues, field['id']! as String)}',
                  style: AppTextStyles.footnote,
                ),
          ],
        ),
      );
    }
    const labels = {
      'title': '标题',
      'note': '备注',
      'status': '状态',
      'priority': '优先级',
      'due_at': '截止时间',
      'remind_rules': '提醒',
      'category_id': '分类',
      'steps': '步骤',
      'tags': '标签',
      'completed_at': '完成时间',
      'repeat_rule': '重复规则',
      'repeat_timezone': '重复时区',
    };
    String show(Object? value, String key) {
      if (key == 'steps') {
        return (value as List? ?? const []).indexed
            .map((pair) {
              final step = pair.$2 as Map;
              return '${pair.$1 + 1}. ${step['title']}${step['done'] == true ? ' ✓' : ''}';
            })
            .join('\n');
      }
      if (key == 'repeat_rule') return repeatLabelOf(value as String?);
      if (key == 'remind_rules') return reminderRulesLabel(value);
      if (key == 'category_id' && value != null) {
        return categories[value] ?? '已不可用的分类';
      }
      if ((key == 'due_at' || key == 'completed_at') && value is String) {
        final date = DateTime.tryParse(value);
        if (date != null) {
          return DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
        }
      }
      if (value == null || value == '') return '无';
      if (value is List) return value.isEmpty ? '无' : value.join('、');
      return switch (value) {
        'done' => '已完成',
        'pending' => '待办',
        'inProgress' => '进行中',
        'none' => '无',
        'high' => '高',
        'medium' => '中',
        'low' => '低',
        'urgent' => '紧急',
        'cancelled' => '已取消',
        _ => '$value',
      };
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$operation ${after['title'] ?? before['title'] ?? '待办'}',
            style: AppTextStyles.subhead,
          ),
          if (change['effects'] is List) ...[
            const SizedBox(height: 4),
            Text(
              '${change['scope'] == 'current' ? '仅本次' : '本次及以后'} '
              '${(change['effects']! as List).where((e) => (e as Map)['kind'] == 'todo').length} 条待办变更',
              style: AppTextStyles.footnote,
            ),
            Text(
              change['scope'] == 'current'
                  ? '只修改选中实例，其他日期继续沿用已有规则。'
                  : change['operation'] == 'delete' ||
                        after['repeat_rule'] == null
                  ? '停止该范围的后续重复，保留其他已完成记录；整体接受或拒绝。'
                  : '系列操作整体接受或拒绝；未来实例按窗口继续生成。',
              style: AppTextStyles.footnote,
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('查看全部变更', style: AppTextStyles.footnote),
              children: [
                for (final effect
                    in (change['effects']! as List).cast<JsonObject>())
                  if (effect['kind'] == 'todo')
                    AgentChangePreview(change: effect)
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '系列模板 '
                        '${effect['operation'] == 'create' ? '新建' : '更新'} '
                        '${repeatLabelOf(((effect['after'] as Map?) ?? (effect['before'] as Map?)?['data'])?['rule'] as String?)} '
                        '时区 ${(effect['after'] as Map?)?['timezone']} '
                        '${(effect['after'] as Map?)?['stop_before'] == null ? '继续重复' : '已设定停止边界'}',
                        style: AppTextStyles.footnote,
                      ),
                    ),
              ],
            ),
          ],
          for (final entry in labels.entries)
            if (change['operation'] == 'delete'
                ? before[entry.key] != null
                : canonicalWorkspaceJson(before[entry.key]) !=
                      canonicalWorkspaceJson(after[entry.key]))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(
                  change['operation'] == 'delete'
                      ? '${entry.value}：${show(before[entry.key], entry.key)}'
                      : '${entry.value}：${show(before[entry.key], entry.key)} → ${show(after[entry.key], entry.key)}',
                  style: AppTextStyles.footnote,
                ),
              ),
        ],
      ),
    );
  }
}
