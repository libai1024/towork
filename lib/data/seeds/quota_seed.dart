import '../../domain/models/models.dart';
import '../../domain/repositories/quota_store.dart' show QuotaDemo;

QuotaState seedQuotaState(QuotaDemo demo) => switch (demo) {
  // 正常：32% / 58% / 41%，全部 brand 色。
  QuotaDemo.normal => QuotaState(
    bars: [
      QuotaBar(
        label: '近 5 小时',
        usedTokens: 9600,
        limitTokens: 30000,
        resetNote: '窗口滚动重置 约 2 小时后',
      ),
      QuotaBar(
        label: '本周',
        usedTokens: 261000,
        limitTokens: 450000,
        resetNote: '周一 04:00 重置',
      ),
      QuotaBar(
        label: '本月',
        usedTokens: 820000,
        limitTokens: 2000000,
        resetNote: '次月 1 日重置',
      ),
    ],
  ),
  // 高用量：5h 85% / 周 88%，>80% 变 orange（规范 §7.2）。
  QuotaDemo.high => QuotaState(
    bars: [
      QuotaBar(
        label: '近 5 小时',
        usedTokens: 25500,
        limitTokens: 30000,
        resetNote: '窗口滚动重置 约 40 分钟后',
      ),
      QuotaBar(
        label: '本周',
        usedTokens: 396000,
        limitTokens: 450000,
        resetNote: '周一 04:00 重置',
      ),
      QuotaBar(
        label: '本月',
        usedTokens: 820000,
        limitTokens: 2000000,
        resetNote: '次月 1 日重置',
      ),
    ],
  ),
  // 403 触顶：5h 100% 变 red + 置顶横幅（§6.3）。
  QuotaDemo.limited => QuotaState(
    bars: [
      QuotaBar(
        label: '近 5 小时',
        usedTokens: 30000,
        limitTokens: 30000,
        resetNote: '窗口结束后自动恢复 约 2 小时后',
      ),
      QuotaBar(
        label: '本周',
        usedTokens: 261000,
        limitTokens: 450000,
        resetNote: '周一 04:00 重置',
      ),
      QuotaBar(
        label: '本月',
        usedTokens: 820000,
        limitTokens: 2000000,
        resetNote: '次月 1 日重置',
      ),
    ],
    limitEvent: LimitEventType.fiveHour,
  ),
  // 零用量空态（§6.2）：条下不显示重置时间，换引导文案。
  QuotaDemo.empty => QuotaState(
    bars: [
      QuotaBar(
        label: '近 5 小时',
        usedTokens: 0,
        limitTokens: 30000,
        resetNote: '窗口滚动重置',
      ),
      QuotaBar(
        label: '本周',
        usedTokens: 0,
        limitTokens: 450000,
        resetNote: '周一 04:00 重置',
      ),
      QuotaBar(
        label: '本月',
        usedTokens: 0,
        limitTokens: 2000000,
        resetNote: '次月 1 日重置',
      ),
    ],
  ),
};
