import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/ai/openai_compatible_gateway.dart';
import 'package:towork/data/ai/provider_quota_gateway.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/quota.dart';

JsonObject _json(String source) =>
    (jsonDecode(source) as Map).cast<String, Object?>();

void main() {
  final now = DateTime.utc(2026, 11, 13, 8);

  group('GLM Coding Plan', () {
    test('wrapped response with 5-hour and weekly credit windows', () {
      final quota = ProviderQuotaGateway.parseZhipuCoding(
        _json('''
{"code":200,"data":{"level":"pro","limits":[
 {"type":"CREDIT_LIMIT","unit":3,"number":5,"usage":12000,"currentValue":3000,"remaining":9000,"percentage":25},
 {"type":"CREDIT_LIMIT","unit":6,"number":1,"usage":60000,"currentValue":60000,"remaining":0,"percentage":100,"nextResetTime":1787649214999}
]}}'''),
        now,
      );
      expect(quota.plan, 'pro');
      expect(quota.windows.map((w) => w.label), ['5 小时', '每周']);
      expect(quota.windows.first.usedRatio, 0.25);
      expect(quota.windows.first.limit, 12000);
      expect(quota.windows.first.resetAt, isNull);
      expect(quota.windows.last.exhausted, isTrue);
      expect(
        quota.windows.last.resetAt,
        DateTime.fromMillisecondsSinceEpoch(1787649214999, isUtc: true),
      );
      expect(quota.exhausted, isTrue);
      expect(quota.recoversAt, quota.windows.last.resetAt);
      expect(quota.tightest!.label, '每周');
    });

    test('older plans carry only a percentage', () {
      final quota = ProviderQuotaGateway.parseZhipuCoding(
        _json('''
{"limits":[
 {"type":"TOKENS_LIMIT","unit":3,"number":5,"percentage":40,"nextResetTime":1787649214999},
 {"type":"TIME_LIMIT","usage":1000,"currentValue":120,"percentage":12}
]}'''),
        now,
      );
      expect(quota.windows.map((w) => w.label), ['5 小时', '联网工具 每月']);
      expect(quota.windows.first.usedRatio, 0.4);
      expect(quota.windows.last.usedRatio, 0.12);
      expect(quota.exhausted, isFalse);
    });

    test('day and month are distinct from the rolling five-hour window', () {
      final quota = ProviderQuotaGateway.parseZhipuCoding(
        _json(
          '{"limits":[{"unit":3,"number":5,"percentage":20},{"unit":4,"number":1,"percentage":36},{"unit":5,"number":1,"percentage":15}]}',
        ),
        now,
      );
      expect(quota.windows.map((w) => w.label), ['5 小时', '每日', '每月']);
    });

    test('unrecognized bodies are a protocol failure, never a guess', () {
      for (final body in ['{}', '{"data":{"limits":[]}}', '{"limits":[{}]}']) {
        expect(
          () => ProviderQuotaGateway.parseZhipuCoding(_json(body), now),
          throwsA(
            isA<ModelFailure>().having(
              (f) => f.code,
              'code',
              ModelFailureCode.protocol,
            ),
          ),
          reason: body,
        );
      }
    });
  });

  group('Kimi Code', () {
    test('counters win over ratio fields that are stuck at zero', () {
      final quota = ProviderQuotaGateway.parseKimiCode(
        _json(
          '''
{"usage":{"limit":"100","used":"29","remaining":"71","resetTime":"2026-10-02T12:58:51.471957Z"},
 "limits":[{"window":{"duration":300,"timeUnit":"TIME_UNIT_MINUTE"},
            "detail":{"limit":"100","used":"88","remaining":"12","resetTime":"2026-10-01T01:58:51.471957Z"}}],
 "usages":{"limit_5h":{"used_ratio":0,"reset_time":"2026-10-01T01:58:50Z"},
           "limit_7d":{"used_ratio":0,"reset_time":"2026-10-02T12:58:50Z"}}}''',
        ),
        now,
      );
      expect(quota.windows.map((w) => w.label), ['5 小时', '周期额度', '每周']);
      expect(quota.windows.first.usedRatio, 0.88);
      expect(quota.windows.first.used, 88);
      expect(
        quota.windows.first.resetAt,
        DateTime.utc(2026, 10, 1, 1, 58, 51, 471, 957),
      );
      expect(quota.windows[1].usedRatio, 0.29);
      expect(quota.windows.last.usedRatio, 0);
      expect(quota.tightest!.label, '5 小时');
    });

    test('remaining-only counters are converted to usage', () {
      final quota = ProviderQuotaGateway.parseKimiCode(
        _json(
          '{"limits":[{"window":{"duration":7,"timeUnit":"TIME_UNIT_DAY"},'
          '"detail":{"limit":200,"remaining":50}}]}',
        ),
        now,
      );
      expect(quota.windows.single.label, '每周');
      expect(quota.windows.single.usedRatio, 0.75);
    });

    test('wrapped and ratio-only shapes are understood', () {
      final wrapped = ProviderQuotaGateway.parseKimiCode(
        _json(
          '{"code":0,"data":{"kind":"ok","quota":{"usages":{'
          '"limit5h":{"usedRatio":0.5,"resetAt":"2026-11-13T10:00:00Z"},'
          '"limit7d":{"usedRatio":1.0}}}}}',
        ),
        now,
      );
      expect(wrapped.windows.map((w) => w.label), ['5 小时', '每周']);
      expect(wrapped.windows.first.usedRatio, 0.5);
      expect(wrapped.windows.first.resetAt, DateTime.utc(2026, 11, 13, 10));
      expect(wrapped.exhausted, isTrue);
      // 用尽但不知道何时重置：恢复时间未知，路由会一直跳过直到刷新。
      expect(wrapped.recoversAt, isNull);

      final ratios = ProviderQuotaGateway.parseKimiCode(
        _json('{"usages":{"limit_5h":{"used_ratio":0.2}}}'),
        now,
      );
      expect(ratios.windows.single.usedRatio, 0.2);
    });

    test('empty bodies are a protocol failure', () {
      expect(
        () => ProviderQuotaGateway.parseKimiCode(_json('{"usages":{}}'), now),
        throwsA(isA<ModelFailure>()),
      );
    });
  });

  test('DeepSeek balance prefers CNY and parses string amounts', () {
    final quota = ProviderQuotaGateway.parseDeepSeek(
      _json(
        '{"is_available":true,"balance_infos":['
        '{"currency":"USD","total_balance":"3.00"},'
        '{"currency":"CNY","total_balance":"110.00","granted_balance":"10.00"}]}',
      ),
      now,
    );
    expect(quota.balance, 110);
    expect(quota.currency, 'CNY');
    expect(quota.exhausted, isFalse);
    final broke = ProviderQuotaGateway.parseDeepSeek(
      _json('{"balance_infos":[{"currency":"CNY","total_balance":"0.00"}]}'),
      now,
    );
    expect(broke.exhausted, isTrue);
    expect(
      () => ProviderQuotaGateway.parseDeepSeek(_json('{}'), now),
      throwsA(isA<ModelFailure>()),
    );
  });

  test('Moonshot balance reads available_balance in CNY', () {
    final quota = ProviderQuotaGateway.parseMoonshot(
      _json(
        '{"code":0,"data":{"available_balance":49.58894,'
        '"voucher_balance":46.58893,"cash_balance":3.00001},"status":true}',
      ),
      now,
    );
    expect(quota.balance, closeTo(49.58894, 1e-9));
    expect(quota.currency, 'CNY');
  });

  test('snapshots survive the cache round trip', () {
    final original = QuotaSnapshot(
      fetchedAt: now,
      plan: 'pro',
      balance: 1.5,
      currency: 'CNY',
      windows: [
        QuotaWindow(
          label: '5 小时',
          usedRatio: 0.4,
          used: 40,
          limit: 100,
          resetAt: now.add(const Duration(hours: 2)),
        ),
        const QuotaWindow(label: '每周', usedRatio: 0.1),
      ],
    );
    final restored = QuotaSnapshot.fromJson(
      _json(jsonEncode(original.toJson())),
    );
    expect(restored.fetchedAt, now);
    expect(restored.plan, 'pro');
    expect(restored.balance, 1.5);
    expect(restored.windows.first.resetAt, now.add(const Duration(hours: 2)));
    expect(restored.windows.first.remainingRatio, closeTo(0.6, 1e-9));
    expect(restored.windows.last.resetAt, isNull);
  });

  group('HTTP failure classification', () {
    ModelFailureCode classify(int status, String body) =>
        OpenAiCompatibleGateway.classifyHttpFailure(status, body);

    test('quota exhaustion is told apart from momentary throttling', () {
      // 智谱把两者都放在 429，只能看错误码。
      expect(
        classify(429, '{"error":{"code":"1308","message":"x"}}'),
        ModelFailureCode.quota,
      );
      expect(
        classify(429, '{"error":{"code":"1310","message":"x"}}'),
        ModelFailureCode.quota,
      );
      expect(
        classify(429, '{"error":{"code":"1302","message":"x"}}'),
        ModelFailureCode.rateLimited,
      );
      expect(
        classify(429, '{"error":{"code":"1311","message":"x"}}'),
        ModelFailureCode.forbidden,
      );
      // Kimi Code 看措辞；偶尔用 403 表达额度用尽。
      expect(
        classify(429, "You've reached your 5-hour usage limit"),
        ModelFailureCode.quota,
      );
      expect(
        classify(403, '{"error":{"message":"weekly (7-day) usage limit"}}'),
        ModelFailureCode.quota,
      );
      expect(
        classify(429, "We're receiving too many requests"),
        ModelFailureCode.rateLimited,
      );
      // Kimi 开放平台看 error.type；DeepSeek 用 402。
      expect(
        classify(429, '{"error":{"type":"exceeded_current_quota_error"}}'),
        ModelFailureCode.quota,
      );
      expect(
        classify(429, '{"error":{"type":"rate_limit_reached_error"}}'),
        ModelFailureCode.rateLimited,
      );
      expect(classify(402, 'Insufficient Balance'), ModelFailureCode.quota);
    });

    test('other statuses keep their existing meaning', () {
      expect(classify(401, ''), ModelFailureCode.authentication);
      expect(classify(403, ''), ModelFailureCode.forbidden);
      expect(classify(404, ''), ModelFailureCode.unavailableModel);
      expect(classify(429, ''), ModelFailureCode.rateLimited);
      expect(classify(500, 'not json'), ModelFailureCode.provider);
      expect(classify(503, '{"error":"busy"}'), ModelFailureCode.provider);
    });
  });
}
