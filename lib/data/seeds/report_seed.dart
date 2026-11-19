import '../../domain/models/models.dart';
import 'seed_palette.dart';

// 分类快照保留与分类种子相同的存储颜色。
final _archiveRef = ReportCategoryRef(
  id: 'cat_archive',
  name: '档案馆',
  color: SeedPalette.cyan,
);
final _stockRef = ReportCategoryRef(
  id: 'cat_stock',
  name: '炒股',
  color: SeedPalette.red,
);
final _familyRef = ReportCategoryRef(
  id: 'cat_family',
  name: '家庭',
  color: SeedPalette.green,
);
final _workRef = ReportCategoryRef(
  id: 'cat_work',
  name: '工作',
  color: SeedPalette.brand,
);

DateTime _guardFuture(DateTime t, DateTime now) =>
    t.isAfter(now) ? now.subtract(const Duration(hours: 1)) : t;

List<Report> seedReports(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final thisMonday = today.subtract(Duration(days: today.weekday - 1));

  (DateTime, DateTime) weekOf(int weeksAgo) {
    final start = thisMonday.subtract(Duration(days: 7 * weeksAgo));
    return (start, start.add(const Duration(days: 6)));
  }

  String weekLabel(DateTime monday) => '第 ${isoWeekNumber(monday)} 周';

  final (w1s, w1e) = weekOf(1);
  final (w2s, w2e) = weekOf(2);
  final (w3s, w3e) = weekOf(3);
  final (w5s, w5e) = weekOf(5);
  final thisMonthFirst = DateTime(today.year, today.month, 1);
  final lastMonthFirst = DateTime(today.year, today.month - 1, 1);
  final lastMonthEnd = thisMonthFirst.subtract(const Duration(days: 1));

  return [
    // 第 38 周周报：未读，定时生成，完整内容
    Report(
      id: 'r1',
      type: ReportType.weekly,
      title: '稳步前进的一周',
      periodLabel: weekLabel(w1s),
      periodStart: w1s,
      periodEnd: w1e,
      summary: '完成率 86% 逾期 2 项 新增档案 28 卷',
      isRead: false,
      source: ReportSource.scheduled,
      categorySnapshot: [_archiveRef, _stockRef, _familyRef, _workRef],
      createdAt: _guardFuture(w1e.add(const Duration(days: 1, hours: 8)), now),
      generatedAt: _guardFuture(
        w1e.add(const Duration(days: 1, hours: 8)),
        now,
      ),
      readingMinutes: 3,
      model: 'k3',
      stats: const ReportStats(
        completionRate: 86,
        doneCount: 24,
        createdCount: 31,
        overdueCount: 2,
        dataRowCount: 28,
        dataRowUnit: '卷',
        completionRateDelta: 5,
        doneCountDelta: 3,
        dataRowNote: '接收 3 批',
      ),
      contentMarkdown: '''## 本周概览
这周的节奏比上周稳。档案馆接收登记按台账推进，股票账户做了一次减仓，家庭事项集中在缴费和年检。整体完成率 **86%**，较上周 **+5pt**。

## 档案馆
- 完成 8 项：季度报告初稿、第三批退休干部档案登记、库房温湿度记录全勤
- 接收档案 3 批共 **28** 卷，数字化加工进度推进到 **68%**
- 借阅登记 2 笔，均已按期归还

## 炒股
- 卖出贵州茅台 500 股，现金占比升至 **34%**
- 宁德时代波动加大，止损提醒挂在 `180`

## 核心数据变动
| 指标 | 上期 | 本期 | 变动 |
| --- | --- | --- | --- |
| 档案接收(卷) | 18 | 28 | **+10** |
| 账户市值(元) | 102,300 | 98,750 | **-3.5%** |
| 库房温度均值(℃) | 21.4 | 20.8 | **-0.6** |

## AI 观察与建议
档案馆的事连续两周都堆在周四集中完成。把接收登记固定到周三下午，周四会松快很多。
季度报告已经改到第 3 版了，周五前发出去就好，别再开新头。

## 逾期与风险
- 「季度报告」已逾期 3 天，周五是最后窗口
- 车辆年检月底到期，本周内预约

## 下期待办
- 发送季度报告给王总 明天 15:00
- 库房季度盘点 周四上午
- 把比亚迪止损计划写进交易计划 下周一''',
    ),
    // 第 37 周周报：已读
    Report(
      id: 'r2',
      type: ReportType.weekly,
      title: '充电与收尾并行',
      periodLabel: weekLabel(w2s),
      periodStart: w2s,
      periodEnd: w2e,
      summary: '完成率 81% 培训 1 次 持仓无交易',
      isRead: true,
      source: ReportSource.scheduled,
      categorySnapshot: [_archiveRef, _stockRef, _familyRef],
      createdAt: _guardFuture(w2e.add(const Duration(days: 1, hours: 8)), now),
      generatedAt: _guardFuture(
        w2e.add(const Duration(days: 1, hours: 8)),
        now,
      ),
      readingMinutes: 2,
      model: 'k3',
      stats: const ReportStats(
        completionRate: 81,
        doneCount: 21,
        createdCount: 24,
        overdueCount: 1,
        dataRowCount: 15,
        dataRowUnit: '卷',
        completionRateDelta: -2,
        doneCountDelta: -2,
        dataRowNote: '接收 2 批',
      ),
      contentMarkdown: '''## 本周概览
本周完成待办 **21** 项，完成率 **81%**，较上周 **-2pt**。参加了馆里的数字化加工培训；家庭事项集中在车辆年检与物业费。持仓无交易，宁德时代波动加大，已设好止损提醒。

## 档案馆
- 完成数字化加工培训并签到，新国标著录要点已同步到笔记
- 接收档案 2 批共 **15** 卷

## 家庭
- 车辆年检已预约，物业费催缴中

## 核心数据变动
| 指标 | 上期 | 本期 | 变动 |
| --- | --- | --- | --- |
| 档案接收(卷) | 22 | 15 | **-7** |
| 账户市值(元) | 101,900 | 102,300 | **+0.4%** |

## AI 观察与建议
培训类事项放在周三效果最好——既不冲周一的启动，也不挤周五的收尾。
物业费连着两周出现在逾期里，建议改成自动提醒。

## 下期待办
- 提交档案数字化项目周报 周三前
- 补缴第四季度物业费 本周内''',
    ),
    // 第 36 周周报：定时生成失败卡片
    Report(
      id: 'r3',
      type: ReportType.weekly,
      title: '${weekLabel(w3s)}周报',
      periodLabel: weekLabel(w3s),
      periodStart: w3s,
      periodEnd: w3e,
      summary: '',
      isRead: true,
      source: ReportSource.scheduled,
      status: ReportStatus.failed,
      failureReason: 'network',
      createdAt: _guardFuture(w3e.add(const Duration(days: 1, hours: 8)), now),
    ),
    // 8 月月报：已读，含引用块与部分失败横幅
    Report(
      id: 'r4',
      type: ReportType.monthly,
      title: '八月：输入与输出的平衡',
      periodLabel: '${lastMonthFirst.year} 年 ${lastMonthFirst.month} 月',
      periodStart: lastMonthFirst,
      periodEnd: lastMonthEnd,
      summary: '完成率 78% 新增 31 项 档案入库 64 卷',
      isRead: true,
      source: ReportSource.scheduled,
      categorySnapshot: [_archiveRef, _stockRef, _familyRef, _workRef],
      createdAt: _guardFuture(
        thisMonthFirst.add(const Duration(hours: 8)),
        now,
      ),
      generatedAt: _guardFuture(
        thisMonthFirst.add(const Duration(hours: 8)),
        now,
      ),
      readingMinutes: 4,
      model: 'k3',
      incompleteSections: const ['炒股'],
      stats: const ReportStats(
        completionRate: 78,
        doneCount: 78,
        createdCount: 92,
        overdueCount: 3,
        dataRowCount: 64,
        dataRowUnit: '卷',
        completionRateDelta: 2,
        doneCountDelta: 9,
        dataRowNote: '接收 9 批',
      ),
      contentMarkdown: '''## 本月概览
> 八月的关键词，是输入与输出的平衡。

完成待办 **78** 项，完成率 **78%**，较七月 **+2pt**。档案接收进入旺季，共入库 **64** 卷；股票账户操作克制，只做了两次调仓。

## 档案馆
- 接收档案 9 批共 **64** 卷，其中基建项目案卷 **8** 卷
- 数字化加工完成 **66** 卷，进度 68%
- 学习了档案著录新国标 `DA/T 18-2022` 修订点

## 炒股
- 减仓贵州茅台 500 股，加仓宁德时代 200 股
- 现金占比从 22% 升至 **34%**

## 核心数据变动
| 指标 | 上月 | 本月 | 变动 |
| --- | --- | --- | --- |
| 档案接收(卷) | 41 | 64 | **+23** |
| 数字化加工(卷) | 120 | 186 | **+66** |
| 账户市值(元) | 96,800 | 102,300 | **+5.7%** |

## AI 观察与建议
你的完成高峰集中在周二、周三的上午。八月里 80% 的逾期发生在「家庭」分类——都不是难事，只是没有固定时间。
九月建议：给缴费类事项统一设到每月 5 号上午，一次清完。

## 逾期与风险
- 「物业费」逾期 2 天后补缴完成，建议设为每月自动提醒
- 「车辆年检」月底到期，九月第一周必须预约

## 下月关注
- 三季度报告定稿并发送给王总
- 库房季度盘点
- 美联储议息会议后的仓位检查''',
    ),
    // 第 35 周周报：已读，归入 8 月分组
    Report(
      id: 'r5',
      type: ReportType.weekly,
      title: '收心的一周',
      periodLabel: weekLabel(w5s),
      periodStart: w5s,
      periodEnd: w5e,
      summary: '完成率 83% 档案接收 22 卷',
      isRead: true,
      source: ReportSource.scheduled,
      categorySnapshot: [_archiveRef, _familyRef],
      createdAt: _guardFuture(w5e.add(const Duration(days: 1, hours: 8)), now),
      generatedAt: _guardFuture(
        w5e.add(const Duration(days: 1, hours: 8)),
        now,
      ),
      readingMinutes: 2,
      model: 'k3',
      stats: const ReportStats(
        completionRate: 83,
        doneCount: 23,
        createdCount: 26,
        overdueCount: 0,
        dataRowCount: 22,
        dataRowUnit: '卷',
        completionRateDelta: 4,
        doneCountDelta: 2,
        dataRowNote: '接收 3 批',
      ),
      contentMarkdown: '''## 本周概览
假期收心的一周，完成待办 **23** 项，完成率 **83%**，较上周 **+4pt**。零逾期，节奏回来了。

## 档案馆
- 接收档案 3 批共 **22** 卷，登记当日完成
- 库房温湿度记录全勤

## 家庭
- 老照片按年份分了袋，扫描方案定了 600dpi

## AI 观察与建议
零逾期的一周，共同点是把「周一上午」留给了规划。这个习惯值得留住。

## 下期待办
- 整理 9 月上半月交易记录
- 给妈妈预约体检复查''',
    ),
  ];
}
