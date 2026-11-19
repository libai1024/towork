import '../settings/model_accounts.dart';
import 'model_gateway.dart';

/// 一次失败后路由该怎么办。
class FailoverAdvice {
  const FailoverAdvice({required this.cooldown, required this.reason});

  /// 这个账户暂停多久。服务商给了重置时间时由调用方覆盖。
  final Duration cooldown;

  /// 冷却原因，展示给用户。
  final String reason;
}

/// 在多个账户之间选择由谁回答。纯函数，不读写任何状态。
abstract final class ModelRouter {
  /// 额度用到这个比例以上的账户排到后面，留给真正需要时再用。
  static const nearlySpent = 0.9;

  /// 按优先级排好的候选账户。
  ///
  /// 排除：没有 Key、不参与路由、在冷却中、已知额度用尽、[exclude] 里的。
  /// [needsVision] 时只留能看图的模型；未收录的模型能力未知，仍然保留，
  /// 排在已知可用的之后。
  static List<ModelAccount> candidates(
    Iterable<ModelAccount> accounts, {
    required DateTime now,
    bool needsVision = false,
    Set<String> exclude = const {},
  }) {
    final scored = <(int, ModelAccount)>[];
    for (final account in accounts) {
      if (!account.hasCredential ||
          !account.autoRoute ||
          exclude.contains(account.id) ||
          account.coolingAt(now)) {
        continue;
      }
      final quota = account.quota;
      if (quota != null && quota.exhausted) {
        final recovers = quota.recoversAt;
        // 重置时间已过说明缓存过期，额度多半已恢复。
        if (recovers == null || recovers.isAfter(now)) continue;
      }
      final preset = account.descriptor.preset(account.profile.model);
      var penalty = 0;
      if (needsVision) {
        if (preset != null && !preset.vision) continue;
        if (preset == null) penalty += 2;
      }
      // 已过重置时间的窗口是过期缓存，不再据此降级。
      final nearly =
          quota?.windows.any(
            (window) =>
                window.usedRatio >= nearlySpent &&
                (window.resetAt == null || window.resetAt!.isAfter(now)),
          ) ??
          false;
      if (nearly) penalty += 1;
      scored.add((penalty, account));
    }
    scored.sort((a, b) {
      final byPenalty = a.$1.compareTo(b.$1);
      if (byPenalty != 0) return byPenalty;
      return a.$2.position.compareTo(b.$2.position);
    });
    return [for (final item in scored) item.$2];
  }

  /// 哪些失败值得换一个账户重试。
  ///
  /// 额度、限流、鉴权、权限、模型不存在、服务商故障：换账户有意义。
  /// 网络、超时、取消、协议、预算：换账户也解决不了，交给用户重试。
  static FailoverAdvice? adviceFor(ModelFailureCode code) => switch (code) {
    ModelFailureCode.quota => const FailoverAdvice(
      cooldown: Duration(hours: 1),
      reason: '额度已用尽',
    ),
    ModelFailureCode.rateLimited => const FailoverAdvice(
      cooldown: Duration(minutes: 1),
      reason: '请求过于频繁',
    ),
    ModelFailureCode.authentication => const FailoverAdvice(
      cooldown: Duration(days: 365),
      reason: 'Key 无效',
    ),
    ModelFailureCode.forbidden => const FailoverAdvice(
      cooldown: Duration(hours: 6),
      reason: '没有访问权限',
    ),
    ModelFailureCode.unavailableModel => const FailoverAdvice(
      cooldown: Duration(hours: 6),
      reason: '模型不可用',
    ),
    ModelFailureCode.provider => const FailoverAdvice(
      cooldown: Duration(minutes: 2),
      reason: '服务暂时异常',
    ),
    _ => null,
  };

  /// 运行记录里的失败码（`model_quota` 这种）对应的建议。
  static FailoverAdvice? adviceForRunFailure(String? failureCode) {
    if (failureCode == null || !failureCode.startsWith('model_')) return null;
    final name = failureCode.substring('model_'.length);
    for (final code in ModelFailureCode.values) {
      if (code.name == name) return adviceFor(code);
    }
    return null;
  }
}
