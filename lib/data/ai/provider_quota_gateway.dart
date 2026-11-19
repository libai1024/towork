import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/ai/model_gateway.dart';
import '../../domain/ai/quota.dart';

/// 各服务商额度接口的客户端。
///
/// 订阅类接口（Kimi Code、GLM Coding Plan）官方没有公开文档，字段取自其
/// 官方命令行工具与插件的源码；解析对缺字段宽松，认不出时报 protocol，
/// 不会编造数字。响应原文不向上传递。
class ProviderQuotaGateway implements QuotaGateway {
  ProviderQuotaGateway({
    HttpClientAdapter? transport,
    this.timeout = const Duration(seconds: 15),
  }) : _dio = Dio() {
    if (transport != null) _dio.httpClientAdapter = transport;
  }

  final Dio _dio;
  final Duration timeout;

  @override
  Future<QuotaSnapshot> fetch(
    ModelProfile profile, {
    required String apiKey,
    required DateTime now,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) throw const ModelFailure(ModelFailureCode.configuration);
    final descriptor = profile.descriptor;
    switch (descriptor.quota) {
      case QuotaSource.none:
        throw const ModelFailure(ModelFailureCode.configuration);
      case QuotaSource.kimiCodeUsages:
        final uri = descriptor.resolve(profile.region, 'usages');
        return parseKimiCode(await _get(uri, 'Bearer $key'), now);
      case QuotaSource.moonshotBalance:
        final uri = descriptor.resolve(profile.region, 'users/me/balance');
        return parseMoonshot(await _get(uri, 'Bearer $key'), now);
      case QuotaSource.deepseekBalance:
        final uri = descriptor.resolve(profile.region, 'user/balance');
        return parseDeepSeek(await _get(uri, 'Bearer $key'), now);
      case QuotaSource.zhipuCodingQuota:
        final base = Uri.parse(descriptor.baseFor(profile.region)!);
        final uri = base.replace(path: '/api/monitor/usage/quota/limit');
        // 官方插件发送不带 Bearer 的原始 Key；部分账户只接受 Bearer。
        // 先按官方写法请求，鉴权失败再换一种。
        try {
          return parseZhipuCoding(await _get(uri, key), now);
        } on ModelFailure catch (failure) {
          if (failure.code != ModelFailureCode.authentication) rethrow;
          return parseZhipuCoding(await _get(uri, 'Bearer $key'), now);
        }
    }
  }

  Future<JsonObject> _get(Uri uri, String authorization) async {
    try {
      final response = await _dio.getUri<String>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Authorization': authorization,
            'Accept': 'application/json',
            'User-Agent': 'ToWork/1.0',
          },
          followRedirects: false,
          maxRedirects: 0,
          connectTimeout: timeout,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
      final Object? decoded = jsonDecode(response.data ?? '');
      if (decoded is JsonObject) return decoded;
      throw const ModelFailure(ModelFailureCode.protocol);
    } on FormatException {
      throw const ModelFailure(ModelFailureCode.protocol);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw ModelFailure(switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => ModelFailureCode.timeout,
        DioExceptionType.badResponse => switch (status) {
          401 => ModelFailureCode.authentication,
          403 => ModelFailureCode.forbidden,
          404 => ModelFailureCode.unavailableModel,
          429 => ModelFailureCode.rateLimited,
          _ => ModelFailureCode.provider,
        },
        _ => ModelFailureCode.network,
      }, statusCode: status);
    }
  }

  void close() => _dio.close(force: true);

  // ---- 解析（纯函数，便于用真实响应样本测试） ----

  static JsonObject? _map(Object? value) =>
      value is Map ? value.cast<String, Object?>() : null;

  static num? _num(Object? value) => switch (value) {
    num number => number,
    String text => num.tryParse(text.trim()),
    _ => null,
  };

  static DateTime? _time(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    final number = _num(value);
    if (number == null || number <= 0) return null;
    // 13 位是毫秒，10 位是秒。
    final millis = number > 100000000000
        ? number.toInt()
        : number.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  static double _ratio(num used, num limit) =>
      limit <= 0 ? 0 : (used / limit).clamp(0.0, 1.0).toDouble();

  /// 智谱 GLM Coding Plan：`{code, data: {level, limits: [...]}}`，也可能不带
  /// 外层包装。`unit: 3` 是按小时的窗口，`unit: 6` 是按周；
  /// `percentage` 是已用百分比。
  static QuotaSnapshot parseZhipuCoding(JsonObject body, DateTime now) {
    final data = _map(body['data']) ?? body;
    final limits = data['limits'];
    if (limits is! List) throw const ModelFailure(ModelFailureCode.protocol);
    final windows = <QuotaWindow>[];
    for (final raw in limits) {
      final item = _map(raw);
      if (item == null) continue;
      final type = item['type'];
      final unit = _num(item['unit']);
      final count = _num(item['number']);
      final label = switch (type) {
        'TIME_LIMIT' => '联网工具 每月',
        _ => switch (unit) {
          3 => '${count?.toInt() ?? 5} 小时',
          4 => (count ?? 1) == 1 ? '每日' : '${count!.toInt()} 天',
          6 => '每周',
          5 => '每月',
          _ => '额度',
        },
      };
      final limit = _num(item['usage']);
      final used = _num(item['currentValue']);
      final percentage = _num(item['percentage']);
      final double ratio;
      if (limit != null && used != null && limit > 0) {
        ratio = _ratio(used, limit);
      } else if (percentage != null) {
        ratio = (percentage / 100).clamp(0.0, 1.0).toDouble();
      } else {
        continue;
      }
      windows.add(
        QuotaWindow(
          label: label,
          usedRatio: ratio,
          used: used,
          limit: limit,
          resetAt: _time(item['nextResetTime']),
        ),
      );
    }
    if (windows.isEmpty) throw const ModelFailure(ModelFailureCode.protocol);
    final level = data['level'];
    return QuotaSnapshot(
      fetchedAt: now,
      windows: windows,
      plan: level is String && level.isNotEmpty ? level : null,
    );
  }

  static String _kimiWindowLabel(JsonObject? window) {
    final duration = _num(window?['duration']);
    final unit = window?['timeUnit'];
    if (duration == null || unit is! String) return '额度';
    if (duration == 1 && unit == 'TIME_UNIT_MONTH') return '每月';
    if (duration == 1 && unit == 'TIME_UNIT_WEEK') return '每周';
    final minutes = switch (unit) {
      'TIME_UNIT_MINUTE' => duration,
      'TIME_UNIT_HOUR' => duration * 60,
      'TIME_UNIT_DAY' => duration * 60 * 24,
      _ => null,
    };
    if (minutes == null) return '额度';
    if (minutes == 7 * 24 * 60) return '每周';
    if (minutes == 24 * 60) return '每日';
    if (minutes % (24 * 60) == 0) return '${minutes ~/ (24 * 60)} 天';
    if (minutes % 60 == 0) return '${minutes ~/ 60} 小时';
    return '${minutes.toInt()} 分钟';
  }

  static QuotaWindow? _kimiCounter(String label, JsonObject? detail) {
    if (detail == null) return null;
    final limit = _num(detail['limit']);
    if (limit == null || limit <= 0) return null;
    final remaining = _num(detail['remaining']);
    final used =
        _num(detail['used']) ?? (remaining == null ? null : limit - remaining);
    if (used == null) return null;
    return QuotaWindow(
      label: label,
      usedRatio: _ratio(used, limit),
      used: used,
      limit: limit,
      resetAt: _time(detail['resetTime']),
    );
  }

  static QuotaWindow? _kimiRatio(String label, JsonObject? entry) {
    if (entry == null) return null;
    final ratio = _num(entry['used_ratio'] ?? entry['usedRatio']);
    if (ratio == null) return null;
    return QuotaWindow(
      label: label,
      usedRatio: ratio.clamp(0.0, 1.0).toDouble(),
      resetAt: _time(entry['reset_time'] ?? entry['resetAt']),
    );
  }

  /// Kimi Code `/usages`。存在三种已知形态：带计数的扁平结构、
  /// `{code, data: {quota: {usages}}}` 包装结构、只有比例的结构。
  /// 计数字段存在时优先用它（比例字段有长期返回 0 的已知问题）。
  static QuotaSnapshot parseKimiCode(JsonObject body, DateTime now) {
    final wrapped = _map(_map(body['data'])?['quota']);
    final root = wrapped ?? _map(body['data']) ?? body;
    final windows = <QuotaWindow>[];
    final limits = root['limits'];
    if (limits is List) {
      for (final raw in limits) {
        final item = _map(raw);
        final window = _kimiCounter(
          _kimiWindowLabel(_map(item?['window'])),
          _map(item?['detail']),
        );
        if (window != null) windows.add(window);
      }
    }
    final summary = _kimiCounter('周期额度', _map(root['usage']));
    if (summary != null) windows.add(summary);
    final usages = _map(root['usages']);
    if (usages != null) {
      for (final (label, keys) in const [
        ('5 小时', ['limit_5h', 'limit5h']),
        ('每日', ['limit_1d', 'limit1d']),
        ('每周', ['limit_7d', 'limit7d']),
        ('每月', ['limit_month_total', 'monthTotal']),
      ]) {
        if (windows.any((window) => window.label == label)) continue;
        for (final key in keys) {
          final window = _kimiRatio(label, _map(usages[key]));
          if (window != null) {
            windows.add(window);
            break;
          }
        }
      }
    }
    if (windows.isEmpty) throw const ModelFailure(ModelFailureCode.protocol);
    return QuotaSnapshot(fetchedAt: now, windows: windows);
  }

  /// DeepSeek `/user/balance`：`{is_available, balance_infos: [{currency,
  /// total_balance}]}`，金额是字符串。优先人民币。
  static QuotaSnapshot parseDeepSeek(JsonObject body, DateTime now) {
    final infos = body['balance_infos'];
    if (infos is! List || infos.isEmpty) {
      throw const ModelFailure(ModelFailureCode.protocol);
    }
    JsonObject? chosen;
    for (final raw in infos) {
      final item = _map(raw);
      if (item == null) continue;
      chosen ??= item;
      if (item['currency'] == 'CNY') chosen = item;
    }
    final balance = _num(chosen?['total_balance']);
    if (balance == null) throw const ModelFailure(ModelFailureCode.protocol);
    final currency = chosen!['currency'];
    return QuotaSnapshot(
      fetchedAt: now,
      balance: balance.toDouble(),
      currency: currency is String ? currency : null,
    );
  }

  /// Kimi 开放平台 `/users/me/balance`：`{data: {available_balance}}`，人民币。
  static QuotaSnapshot parseMoonshot(JsonObject body, DateTime now) {
    final balance = _num(_map(body['data'])?['available_balance']);
    if (balance == null) throw const ModelFailure(ModelFailureCode.protocol);
    return QuotaSnapshot(
      fetchedAt: now,
      balance: balance.toDouble(),
      currency: 'CNY',
    );
  }
}
