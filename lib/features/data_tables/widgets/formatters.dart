import 'package:towork/l10n/strings.dart';

import '../../../domain/data_tables/business_validation.dart';
import '../../../domain/workspace/workspace_commands.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/models/models.dart';

/// 数据表通用格式化与小工具（纯函数，无状态）。

/// Kimi 式相对时间：刚刚 / N 分钟前 / 今天 HH:mm / 昨天 HH:mm / M月d日 / yyyy/M/d。
String relativeTime(DateTime t) {
  final now = DateTime.now();
  if (t.isAfter(now)) return strings.justNow;
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return strings.justNow;
  if (diff.inMinutes < 60) return strings.minAgo(diff.inMinutes);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final days = today.difference(day).inDays;
  final hm =
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  if (days == 0) return strings.todayRelativetimelabel(hm);
  if (days == 1) return strings.yesterdayRelativetimelabel(hm);
  if (t.year == now.year) return strings.formattedValue(t.month, t.day);
  return '${t.year}/${t.month}/${t.day}';
}

String _decimalDisplay(String raw, {int? scale}) {
  try {
    final value = canonicalBusinessDecimal(raw, scale: scale);
    final parts = value.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$whole${parts.length == 2 ? '.${parts.last}' : ''}';
  } on WorkspaceFailure {
    return raw;
  }
}

/// 按字段类型渲染值：money 千分位 + ¥ 前缀，number 带单位，bool 是/否。
String formatCellValue(DataColumnDef column, String? raw) {
  if (raw == null || raw.isEmpty) return '';
  switch (column.fieldType) {
    case DataFieldType.money:
      return '¥${_decimalDisplay(raw, scale: column.scale)}';
    case DataFieldType.number:
      final display = _decimalDisplay(raw);
      return column.unit == null ? display : '$display ${column.unit}';
    case DataFieldType.boolean:
      return raw == 'true' ? strings.yes : strings.no;
    case DataFieldType.text:
    case DataFieldType.date:
    case DataFieldType.selection:
      return raw;
    case DataFieldType.datetime:
      final parsed = DateTime.tryParse(raw);
      return parsed == null ? raw : formatDateTime(parsed.toLocal());
  }
}

/// 数字/金额值用 Inter tabular figures（规范 §2.1）。
TextStyle tabularStyle(TextStyle base) =>
    base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// 数值类字段右对齐 + tabular figures。
bool isNumericColumn(DataColumnDef column) =>
    column.fieldType == DataFieldType.number ||
    column.fieldType == DataFieldType.money;

String boolRaw(bool v) => v ? 'true' : 'false';

String formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String formatDateTime(DateTime d) => DateFormat('yyyy-MM-dd HH:mm').format(d);

/// 表图标键 → Lucide 图标（模板/表列表共用）。
IconData tableIcon(String iconKey) => switch (iconKey) {
  'archive' => LucideIcons.archive,
  'trendingUp' => LucideIcons.trendingUp,
  'wallet' => LucideIcons.wallet,
  'users' => LucideIcons.users,
  'activity' => LucideIcons.activity,
  _ => LucideIcons.table,
};

/// 字段类型的中文名（新建表/字段预览用）。
String fieldTypeLabel(String type) => switch (type) {
  'number' => strings.number,
  'money' || 'currency' => strings.currency,
  'date' => strings.date,
  'datetime' => strings.dateAndTime,
  'enum' => strings.singleSelect,
  'bool' => strings.switchLabel,
  _ => strings.text,
};
