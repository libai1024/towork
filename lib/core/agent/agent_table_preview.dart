import 'package:flutter/material.dart';

import '../../domain/ai/model_gateway.dart';
import '../../domain/workspace/workspace_commands.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Field-level preview shares the existing durable approval card and its actions.
class AgentTablePreview extends StatelessWidget {
  const AgentTablePreview({super.key, required this.change});
  final JsonObject change;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final before = ((change['before'] as Map?)?['data'] as Map?) ?? {};
    final after = change['after']! as Map;
    final oldFields = {
      for (final field in before['fields'] as List? ?? [])
        (field as Map)['id']: field,
    };
    final newFields = {
      for (final field in after['fields'] as List) (field as Map)['id']: field,
    };
    final create = change['operation'] == 'create';
    final lines = <String>[
      if (!create && before['name'] != after['name'])
        '名称　${before['name']} → ${after['name']}',
      if (before['description'] != after['description'] &&
          (after['description'] != '' || !create))
        '说明　${create ? '' : '${_text(before['description'])} → '}${_text(after['description'])}',
      for (final entry in newFields.entries)
        if (!oldFields.containsKey(entry.key))
          '${create ? '' : '新增字段　'}${_field(entry.value)}'
        else if (canonicalWorkspaceJson(oldFields[entry.key]) !=
            canonicalWorkspaceJson(entry.value))
          '修改字段　${_field(oldFields[entry.key]!)} → ${_field(entry.value)}',
      for (final entry in oldFields.entries)
        if (!newFields.containsKey(entry.key)) '移除字段　${_field(entry.value)}',
    ];
    final rows = [
      ['字段', '类型', '要求'],
      for (final field in newFields.values)
        [
          '${field['name']}',
          _type(field),
          field['required'] == true ? '必填' : '选填',
        ],
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${create ? '新增表格' : '编辑表格'} ${after['name']}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          ),
          if (create) ...[
            if (after['description'] != null && after['description'] != '')
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(
                  '${after['description']}',
                  style: AppTextStyles.caption.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
              ),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.1),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(.6),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                for (var i = 0; i < rows.length; i++)
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: c.separator, width: .5),
                      ),
                    ),
                    children: [
                      for (final value in rows[i])
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 2,
                          ),
                          child: Text(
                            value,
                            style: i == 0
                                ? AppTextStyles.caption.copyWith(
                                    color: c.labelSecondary,
                                  )
                                : AppTextStyles.footnote.copyWith(
                                    color: c.labelPrimary,
                                  ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ] else
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(
                  line,
                  style: AppTextStyles.footnote.copyWith(
                    color: c.labelSecondary,
                  ),
                ),
              ),
          if (lines.isEmpty) Text('内容与当前表格一致', style: AppTextStyles.footnote),
        ],
      ),
    );
  }

  static String _text(Object? value) =>
      value == null || value == '' ? '无' : '$value';

  static String _field(Map<Object?, Object?> field) =>
      '${field['name']} ${_type(field)} ${field['required'] == true ? '必填' : '选填'}';

  static String _type(Map<Object?, Object?> field) {
    final type = switch (field['type']) {
      'number' => '数字',
      'money' => '金额 ${field['scale']} 位小数',
      'date' => '日期',
      'datetime' => '日期时间',
      'selection' => '单选',
      'boolean' => '是否',
      _ => '文本',
    };
    final options = field['options'] as List? ?? [];
    return '$type'
        '${field['unit'] == null ? '' : ' ${field['unit']}'}'
        '${options.isEmpty ? '' : '（${options.join('、')}）'}';
  }
}
