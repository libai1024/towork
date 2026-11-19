import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/ai/model_router.dart';
import 'package:towork/domain/ai/quota.dart';
import 'package:towork/domain/settings/model_accounts.dart';

void main() {
  final now = DateTime.utc(2026, 11, 13, 8);

  ModelAccount account(
    String id,
    ProviderKind kind,
    String model, {
    int position = 0,
    bool key = true,
    bool auto = true,
    DateTime? cooldown,
    QuotaSnapshot? quota,
    String? baseUrl,
  }) => ModelAccount(
    id: id,
    profile: ModelProfile(model: model, product: kind, baseUrl: baseUrl),
    credentialRef: key ? 'ref-$id' : null,
    position: position,
    autoRoute: auto,
    cooldownUntil: cooldown,
    quota: quota,
  );

  List<String> ids(Iterable<ModelAccount> accounts) => [
    for (final item in accounts) item.id,
  ];

  test('orders by priority and drops unusable accounts', () {
    final ranked = ModelRouter.candidates([
      account('c', ProviderKind.deepseek, 'deepseek-flash', position: 2),
      account('a', ProviderKind.kimiCode, 'kimi-for-coding'),
      account('nokey', ProviderKind.zhipu, 'glm-4.7', position: 1, key: false),
      account(
        'manual',
        ProviderKind.zhipu,
        'glm-4.7',
        position: 1,
        auto: false,
      ),
      account(
        'cooling',
        ProviderKind.zhipuCoding,
        'glm-5.3',
        position: 1,
        cooldown: now.add(const Duration(minutes: 5)),
      ),
      account(
        'recovered',
        ProviderKind.zhipuCoding,
        'glm-5.3',
        position: 1,
        cooldown: now.subtract(const Duration(minutes: 5)),
      ),
    ], now: now);
    expect(ids(ranked), ['a', 'recovered', 'c']);
    expect(ids(ModelRouter.candidates(ranked, now: now, exclude: {'a'})), [
      'recovered',
      'c',
    ]);
  });

  test('exhausted quota is skipped until its reset time passes', () {
    QuotaSnapshot spent(DateTime? reset) => QuotaSnapshot(
      fetchedAt: now,
      windows: [QuotaWindow(label: '5 小时', usedRatio: 1, resetAt: reset)],
    );
    final accounts = [
      account(
        'later',
        ProviderKind.kimiCode,
        'kimi-for-coding',
        quota: spent(now.add(const Duration(hours: 1))),
      ),
      account(
        'unknown',
        ProviderKind.kimiCode,
        'kimi-for-coding',
        position: 1,
        quota: spent(null),
      ),
      account(
        'stale',
        ProviderKind.kimiCode,
        'kimi-for-coding',
        position: 2,
        quota: spent(now.subtract(const Duration(minutes: 1))),
      ),
      account(
        'broke',
        ProviderKind.deepseek,
        'deepseek-flash',
        position: 3,
        quota: QuotaSnapshot(fetchedAt: now, balance: 0, currency: 'CNY'),
      ),
    ];
    expect(ids(ModelRouter.candidates(accounts, now: now)), ['stale']);
  });

  test('nearly spent accounts yield to ones with headroom', () {
    final ranked = ModelRouter.candidates([
      account(
        'tight',
        ProviderKind.kimiCode,
        'kimi-for-coding',
        quota: QuotaSnapshot(
          fetchedAt: now,
          windows: [
            QuotaWindow(
              label: '5 小时',
              usedRatio: 0.95,
              resetAt: now.add(const Duration(hours: 2)),
            ),
          ],
        ),
      ),
      account('roomy', ProviderKind.deepseek, 'deepseek-flash', position: 1),
    ], now: now);
    expect(ids(ranked), ['roomy', 'tight']);
  });

  test('vision requests only reach models that accept images', () {
    final accounts = [
      account('text', ProviderKind.zhipuCoding, 'glm-5.3'),
      account(
        'unknown',
        ProviderKind.custom,
        'some-model',
        position: 1,
        baseUrl: 'https://relay.example.com/v1',
      ),
      account('vision', ProviderKind.deepseek, 'deepseek-flash', position: 2),
    ];
    // 已知能看图的优先；能力未知的保留在后面；已知不能的排除。
    expect(ids(ModelRouter.candidates(accounts, now: now, needsVision: true)), [
      'vision',
      'unknown',
    ]);
    expect(ids(ModelRouter.candidates(accounts, now: now)), [
      'text',
      'unknown',
      'vision',
    ]);
  });

  test('only provider-side failures justify switching accounts', () {
    for (final code in [
      ModelFailureCode.quota,
      ModelFailureCode.rateLimited,
      ModelFailureCode.authentication,
      ModelFailureCode.forbidden,
      ModelFailureCode.unavailableModel,
      ModelFailureCode.provider,
    ]) {
      expect(ModelRouter.adviceFor(code), isNotNull, reason: code.name);
      expect(
        ModelRouter.adviceForRunFailure('model_${code.name}'),
        isNotNull,
        reason: code.name,
      );
    }
    for (final code in [
      ModelFailureCode.network,
      ModelFailureCode.timeout,
      ModelFailureCode.cancelled,
      ModelFailureCode.protocol,
      ModelFailureCode.truncated,
      ModelFailureCode.budget,
      ModelFailureCode.contextBudget,
      ModelFailureCode.configuration,
    ]) {
      expect(ModelRouter.adviceFor(code), isNull, reason: code.name);
    }
    expect(ModelRouter.adviceForRunFailure(null), isNull);
    expect(ModelRouter.adviceForRunFailure('agent_invalid'), isNull);
    expect(ModelRouter.adviceForRunFailure('workspace_notFound'), isNull);
    // 额度用尽要等窗口重置，冷却远长于一时限流。
    expect(
      ModelRouter.adviceFor(ModelFailureCode.quota)!.cooldown,
      greaterThan(
        ModelRouter.adviceFor(ModelFailureCode.rateLimited)!.cooldown,
      ),
    );
  });
}
