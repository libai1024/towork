import '../domain/ai/model_gateway.dart';

/// 模型与本地数据之间的时间换算。
///
/// 业务库只存 UTC；让模型自己减 8 小时是「明天下午三点」算错的主要来源。
/// 所以模型一律写「本地时刻 + 偏移」（`2026-11-15T15:00:00+08:00`），由这里
/// 换算成 UTC 再交给领域校验；读回的 UTC 时间同样在这里补一份本地时刻。
class AgentTime {
  static final _stamp = RegExp(
    r'^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d)(?::(\d\d)(?:\.(\d{1,6}))?)?'
    r'(Z|[+-]\d\d:?\d\d)$',
  );
  static final _canonical = RegExp(
    r'^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,6})?Z$',
  );

  /// 工具参数里按「时间点」理解的键。
  static const instantKeys = {'due_at', 'remind_at', 'due_from', 'due_before'};

  /// 工具结果里需要补本地时刻的键。
  ///
  /// 只补用户会问到的时刻；创建与更新时间很少被复述，不为它们多花字节。
  static const _resultKeys = {
    'due_at',
    'remind_at',
    'completed_at',
    'occurrence_at',
    'absolute_at',
  };

  /// 带偏移或 `Z` 的时间换成领域层接受的 UTC 写法。无法识别的值原样返回，
  /// 交给领域校验拒绝——这里不猜没有偏移的时间属于哪个时区。
  static Object? toUtc(Object? value) {
    if (value is! String || _canonical.hasMatch(value)) return value;
    final match = _stamp.firstMatch(value);
    if (match == null) return value;
    int part(int group) => int.parse(match.group(group)!);
    final fraction = (match.group(7) ?? '').padRight(6, '0');
    final local = DateTime.utc(
      part(1),
      part(2),
      part(3),
      part(4),
      part(5),
      match.group(6) == null ? 0 : part(6),
      0,
      fraction.isEmpty ? 0 : int.parse(fraction),
    );
    // DateTime 会把 2 月 30 日滚到 3 月；不存在的日期必须被拒绝而不是改写。
    if (local.year != part(1) ||
        local.month != part(2) ||
        local.day != part(3) ||
        local.hour != part(4) ||
        local.minute != part(5) ||
        (match.group(6) != null && local.second != part(6))) {
      return value;
    }
    final zone = match.group(8)!;
    var offset = Duration.zero;
    if (zone != 'Z') {
      final digits = zone.substring(1).replaceAll(':', '');
      final hours = int.parse(digits.substring(0, 2));
      final minutes = int.parse(digits.substring(2));
      if (hours > 14 || minutes > 59) return value;
      offset = Duration(hours: hours, minutes: minutes);
      if (zone.startsWith('-')) offset = -offset;
    }
    return local.subtract(offset).toIso8601String();
  }

  /// 归一化一次工具调用的参数：顶层与 `patch` 内的时间键。
  static JsonObject normalize(JsonObject args) {
    JsonObject convert(JsonObject source) => {
      for (final entry in source.entries)
        entry.key: instantKeys.contains(entry.key)
            ? toUtc(entry.value)
            : entry.value,
    };
    final next = convert(args);
    final patch = next['patch'];
    if (patch is Map<String, Object?>) next['patch'] = convert(patch);
    return next;
  }

  static String offsetLabel(Duration offset) {
    final minutes = offset.inMinutes.abs();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${offset.isNegative ? '-' : '+'}${two(minutes ~/ 60)}:${two(minutes % 60)}';
  }

  /// `2026-11-15T15:00+08:00`：给模型看的本地时刻，分钟精度已足够复述。
  static String local(DateTime instant, Duration offset) {
    final shifted = instant.toUtc().add(offset);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${shifted.year.toString().padLeft(4, '0')}-${two(shifted.month)}-'
        '${two(shifted.day)}T${two(shifted.hour)}:${two(shifted.minute)}'
        '${offsetLabel(offset)}';
  }

  /// 给查询结果里的 UTC 时间补一个 `<键>_local`，模型复述时不必自己换算。
  static Object? localize(Object? value, Duration offset) {
    if (value is List) {
      return [for (final item in value) localize(item, offset)];
    }
    if (value is! Map) return value;
    final next = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key as String;
      final item = entry.value;
      next[key] = localize(item, offset);
      if (_resultKeys.contains(key) &&
          item is String &&
          _canonical.hasMatch(item)) {
        final parsed = DateTime.tryParse(item);
        if (parsed != null) next['${key}_local'] = local(parsed, offset);
      }
    }
    return next;
  }
}
