import 'model_gateway.dart';

/// 一个额度窗口：订阅的 5 小时/每周/每月用量，或其他按次计数的限制。
class QuotaWindow {
  const QuotaWindow({
    required this.label,
    required this.usedRatio,
    this.used,
    this.limit,
    this.resetAt,
  });

  /// 「5 小时」「每周」这类窗口名。
  final String label;

  /// 已用比例，0–1。
  final double usedRatio;
  final num? used;
  final num? limit;

  /// 窗口重置时间（UTC）；服务商不返回时为空。
  final DateTime? resetAt;

  double get remainingRatio => (1 - usedRatio).clamp(0.0, 1.0);
  bool get exhausted => usedRatio >= 0.999;

  JsonObject toJson() => {
    'label': label,
    'used_ratio': usedRatio,
    if (used != null) 'used': used,
    if (limit != null) 'limit': limit,
    if (resetAt != null) 'reset_at': resetAt!.toUtc().millisecondsSinceEpoch,
  };

  factory QuotaWindow.fromJson(JsonObject json) => QuotaWindow(
    label: json['label']! as String,
    usedRatio: (json['used_ratio']! as num).toDouble(),
    used: json['used'] as num?,
    limit: json['limit'] as num?,
    resetAt: json['reset_at'] is int
        ? DateTime.fromMillisecondsSinceEpoch(
            json['reset_at']! as int,
            isUtc: true,
          )
        : null,
  );
}

/// 一次额度查询的结果。来自服务商接口，不是本机估算。
class QuotaSnapshot {
  QuotaSnapshot({
    required this.fetchedAt,
    List<QuotaWindow> windows = const [],
    this.balance,
    this.currency,
    this.plan,
  }) : windows = List.unmodifiable(windows);

  final DateTime fetchedAt;
  final List<QuotaWindow> windows;

  /// 按量计费账户的可用余额。
  final double? balance;
  final String? currency;

  /// 套餐档位名（服务商返回时才有）。
  final String? plan;

  /// 最紧张的窗口：路由据此判断是否还有余量。
  QuotaWindow? get tightest {
    QuotaWindow? worst;
    for (final window in windows) {
      if (worst == null || window.usedRatio > worst.usedRatio) worst = window;
    }
    return worst;
  }

  /// 订阅窗口用尽，或按量余额归零。
  bool get exhausted =>
      windows.any((window) => window.exhausted) ||
      (balance != null && balance! <= 0);

  /// 用尽后最早什么时候恢复；未知时为空。
  DateTime? get recoversAt {
    DateTime? latest;
    for (final window in windows.where((w) => w.exhausted)) {
      final reset = window.resetAt;
      if (reset == null) return null;
      if (latest == null || reset.isAfter(latest)) latest = reset;
    }
    return latest;
  }

  JsonObject toJson() => {
    'fetched_at': fetchedAt.toUtc().millisecondsSinceEpoch,
    'windows': [for (final window in windows) window.toJson()],
    if (balance != null) 'balance': balance,
    if (currency != null) 'currency': currency,
    if (plan != null) 'plan': plan,
  };

  factory QuotaSnapshot.fromJson(JsonObject json) => QuotaSnapshot(
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(
      json['fetched_at']! as int,
      isUtc: true,
    ),
    windows: [
      for (final item in (json['windows'] as List? ?? const []))
        QuotaWindow.fromJson((item as Map).cast<String, Object?>()),
    ],
    balance: (json['balance'] as num?)?.toDouble(),
    currency: json['currency'] as String?,
    plan: json['plan'] as String?,
  );
}

/// 查询服务商额度。实现只返回类型化结果，不向上抛服务商原文。
abstract interface class QuotaGateway {
  /// 该服务商没有额度接口时抛 [ModelFailureCode.configuration]。
  Future<QuotaSnapshot> fetch(
    ModelProfile profile, {
    required String apiKey,
    required DateTime now,
  });
}
