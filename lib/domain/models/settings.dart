export '../ai/permission_policy.dart' show AiWritePermission;

class UserProfile {
  const UserProfile({
    required this.nickname,
    required this.tier,
    this.avatarUrl,
  });

  final String nickname;

  /// 档位名，如 "Allegretto"（规范 §7.1）。
  final String tier;
  final String? avatarUrl;
}

class QuotaInfo {
  const QuotaInfo({
    required this.usedPct5h,
    required this.usedPctWeekly,
    required this.usedPctMonthly,
  });

  final double usedPct5h;
  final double usedPctWeekly;
  final double usedPctMonthly;
}

// ---------------------------------------------------------------------------
// 设置与 AI 额度（09-settings-quota.md §8）
// ---------------------------------------------------------------------------

/// 按场景分配模型（F7.2 四场景）。
enum ModelScenario {
  intent('意图识别'),
  chat('日常对话'),
  report('报告生成'),
  vision('截图分析');

  const ModelScenario(this.label);

  final String label;
}

/// 可选模型（§8 available_models[]）。
class AiModel {
  const AiModel({required this.id, required this.note, this.unlocked = true});

  final String id;

  /// 一行说明：上下文长度 / 额度消耗倍率等。
  final String note;

  /// 当前档位是否解锁；未解锁行不可选。
  final bool unlocked;
}

/// 档位能力清单项（规范 §7.2）。
class TierCapability {
  const TierCapability({required this.name, required this.unlocked});

  final String name;
  final bool unlocked;
}

/// 单条用量条（应用侧自统计估算口径，分母非官方数据，规范 §7.2）。
class QuotaBar {
  const QuotaBar({
    required this.label,
    required this.usedTokens,
    required this.limitTokens,
    required this.resetNote,
  });

  final String label;
  final int usedTokens;

  /// 估算上限（档位映射默认值，可在「高级」中按 Console 修正）。
  final int limitTokens;
  final String resetNote;

  double get fraction =>
      limitTokens <= 0 ? 0 : (usedTokens / limitTokens).clamp(0.0, 1.0);

  int get percent => (fraction * 100).round();
}

/// 403 触顶事件类型（§6.3 四种文案）。
enum LimitEventType { fiveHour, weekly, monthly, concurrent }

/// 额度页聚合状态：三条用量条 + 触顶事件（「知道了」本次会话内不再出现）。
class QuotaState {
  QuotaState({
    required List<QuotaBar> bars,
    this.limitEvent,
    this.limitEventDismissed = false,
  }) : bars = List<QuotaBar>.unmodifiable(bars);

  /// 固定顺序：近 5 小时 / 本周 / 本月。
  final List<QuotaBar> bars;
  final LimitEventType? limitEvent;
  final bool limitEventDismissed;

  bool get showLimitBanner => limitEvent != null && !limitEventDismissed;
}

/// 服务端连接状态（mock 只读）。
class ServerConnection {
  const ServerConnection({required this.connected, required this.address});

  final bool connected;
  final String address;
}
