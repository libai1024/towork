import '../domain/ai/agent_run.dart';
import '../domain/ai/model_gateway.dart';
import 'agent_time.dart';

/// 模型侧的 `reminders` 与库内 `remind_rules` 之间的转换。
///
/// 待办只有带提醒规则才会发通知；此前 Agent 不能设置规则，「九点提醒我」
/// 建出来的待办到点并不会响。规则 ID 由 App 生成，模型不能直接提交
/// `remind_rules` / `remind_at`。
class AgentReminders {
  static const maxItems = 5;
  static const _maxMinutes = 366 * 24 * 60;

  static const JsonObject schema = {
    'type': 'array',
    'maxItems': maxItems,
    'description':
        'Notifications for this todo; replaces the existing list, [] clears. '
        'Each item is either {"minutes_before": N} relative to due_at (0 = at '
        'the due time) or {"at": "<ISO-8601 with offset>"}. A todo never '
        'notifies without an entry: when the user says 提醒我/叫我/到时候说一声, '
        'add {"minutes_before": 0}. Repeating todos keep only minutes_before.',
    'items': {
      'type': 'object',
      'properties': {
        'minutes_before': {
          'type': 'integer',
          'minimum': 0,
          'maximum': _maxMinutes,
        },
        'at': {'type': 'string'},
      },
      'additionalProperties': false,
    },
  };

  static Never _invalid() => throw const AgentFailure(AgentFailureCode.invalid);

  /// 顶层与 `patch` 内的 `reminders` 换成 `remind_rules`。
  static JsonObject translate(JsonObject args) {
    final next = _convert(args);
    final patch = next['patch'];
    if (patch is Map<String, Object?>) next['patch'] = _convert(patch);
    return next;
  }

  static JsonObject _convert(JsonObject source) {
    if (source.containsKey('remind_rules') || source.containsKey('remind_at')) {
      _invalid();
    }
    if (!source.containsKey('reminders')) return {...source};
    final raw = source['reminders'];
    if (raw is! List || raw.length > maxItems) _invalid();
    final rules = <JsonObject>[];
    final seen = <String>{};
    for (final item in raw) {
      if (item is! Map<String, Object?> ||
          item.length != 1 ||
          !(item.containsKey('minutes_before') || item.containsKey('at'))) {
        _invalid();
      }
      final JsonObject rule;
      if (item.containsKey('minutes_before')) {
        final minutes = item['minutes_before'];
        if (minutes is! int || minutes < 0 || minutes > _maxMinutes) {
          _invalid();
        }
        rule = {'offset_minutes': minutes};
      } else {
        final at = AgentTime.toUtc(item['at']);
        if (at is! String) _invalid();
        rule = {'absolute_at': at};
      }
      // 同一时刻说两遍只留一条，通知不会重复响。
      if (!seen.add(rule.toString())) continue;
      rules.add({'id': 'ag_${rules.length + 1}', ...rule});
    }
    return {
      for (final entry in source.entries)
        if (entry.key != 'reminders') entry.key: entry.value,
      'remind_rules': rules,
    };
  }

  /// 相对提醒必须有截止时间可依附，否则永远不会触发。
  static bool danglingOffset(Map<String, Object?> todo) =>
      todo['due_at'] == null &&
      (todo['remind_rules'] as List? ?? const []).any(
        (rule) => rule is Map && rule['offset_minutes'] != null,
      );
}
