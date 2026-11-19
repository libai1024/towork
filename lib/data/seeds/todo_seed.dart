import '../../domain/models/models.dart';

List<Todo> seedTodos(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(DateTime day, int h, [int m = 0]) =>
      DateTime(day.year, day.month, day.day, h, m);
  final tomorrow = today.add(const Duration(days: 1));

  final seeds = <Todo>[
    // 今天
    Todo(
      id: 't1',
      title: '下午三点前把季度报告发给王总',
      note: '记得用最新模板，抄送李经理',
      status: TodoStatus.inProgress,
      priority: TodoPriority.high,
      dueAt: at(today, 15),
      remindAt: at(today, 14, 30),
      remindRules: [
        const RemindRule(id: 'rr_t1_1', offsetMinutes: 30),
        const RemindRule(id: 'rr_t1_2', offsetMinutes: 0),
      ],
      categoryId: 'cat_work',
      source: TodoSource.ai,
      sourceMessageId: 'm_seed_1',
      tags: const ['急活', '客户'],
      createdAt: at(today, 9, 12),
    ),
    Todo(
      id: 't2',
      title: '整理上午接收的 12 卷退休干部档案并登记',
      priority: TodoPriority.medium,
      dueAt: at(today, 17, 30),
      categoryId: 'cat_archive_in',
      createdAt: at(today, 8, 40),
    ),
    Todo(
      id: 't3',
      title: '收盘后复盘宁德时代走势，更新持仓表',
      dueAt: at(today, 16),
      categoryId: 'cat_stock_position',
      source: TodoSource.ai,
      sourceMessageId: 'm_seed_3',
      createdAt: at(today, 9, 30),
    ),
    Todo(
      id: 't4',
      title: '给妈妈回电话，问体检报告取没取',
      dueAt: at(today, 20),
      repeatRule: 'FREQ=WEEKLY;BYDAY=SU',
      categoryId: 'cat_family',
      createdAt: at(today, 10, 5),
    ),
    // 明天 / 下周
    Todo(
      id: 't5',
      title: '明天上午去馆里库房核对 2024 年接收台账',
      dueAt: at(tomorrow, 9, 30),
      categoryId: 'cat_archive_in',
      priority: TodoPriority.medium,
      createdAt: at(today, 9, 50),
    ),
    Todo(
      id: 't6',
      title: '下周三前提交档案数字化项目周报',
      dueAt: at(today.add(const Duration(days: 3)), 18),
      categoryId: 'cat_work',
      priority: TodoPriority.medium,
      createdAt: at(today, 11, 20),
    ),
    Todo(
      id: 't7',
      title: '下周一把比亚迪的止损计划写进交易计划',
      dueAt: at(today.add(const Duration(days: 4)), 10),
      categoryId: 'cat_stock_plan',
      createdAt: at(today, 11, 40),
    ),
    // 逾期
    Todo(
      id: 't8',
      title: '补缴第四季度物业费',
      note: '物业催了两次，微信缴费即可',
      dueAt: at(today.subtract(const Duration(days: 2)), 18),
      categoryId: 'cat_family',
      priority: TodoPriority.urgent,
      createdAt: at(today.subtract(const Duration(days: 5)), 19),
    ),
    Todo(
      id: 't9',
      title: '归还老李借走的两卷基建档案',
      dueAt: at(today.subtract(const Duration(days: 1)), 12),
      categoryId: 'cat_archive_lend',
      createdAt: at(today.subtract(const Duration(days: 3)), 14),
    ),
    Todo(
      id: 't10',
      title: '车辆年检预约（月底前到期）',
      dueAt: at(today.subtract(const Duration(days: 4)), 9),
      categoryId: 'cat_family',
      createdAt: at(today.subtract(const Duration(days: 8)), 20),
    ),
    // 无截止
    Todo(
      id: 't11',
      title: '研究一下可转债打新规则',
      categoryId: 'cat_stock',
      priority: TodoPriority.low,
      tags: const ['学习'],
      createdAt: at(today.subtract(const Duration(days: 1)), 22, 15),
    ),
    Todo(
      id: 't12',
      title: '整理书房抽屉里的老照片，考虑扫描归档',
      categoryId: 'cat_family',
      createdAt: at(today.subtract(const Duration(days: 2)), 21),
    ),
    Todo(
      id: 't13',
      title: '学习档案著录新国标 DA/T 18-2022 修订点',
      categoryId: 'cat_archive',
      createdAt: at(today.subtract(const Duration(days: 2)), 15),
    ),
    Todo(
      id: 't14',
      title: '列一张家庭年度体检清单',
      categoryId: 'cat_family',
      createdAt: at(today.subtract(const Duration(days: 3)), 20, 40),
    ),
    // 已完成
    Todo(
      id: 't15',
      title: '卖出 500 股贵州茅台，回笼资金',
      status: TodoStatus.done,
      categoryId: 'cat_stock_position',
      dueAt: at(today.subtract(const Duration(days: 1)), 15),
      createdAt: at(today.subtract(const Duration(days: 3)), 10),
      completedAt: at(today.subtract(const Duration(days: 1)), 14, 32),
    ),
    Todo(
      id: 't16',
      title: '完成上周档案接收记录的数据录入',
      status: TodoStatus.done,
      categoryId: 'cat_archive_in',
      createdAt: at(today.subtract(const Duration(days: 4)), 9),
      completedAt: at(today.subtract(const Duration(days: 2)), 16, 45),
    ),
    Todo(
      id: 't17',
      title: '给阳台的绿萝换盆',
      status: TodoStatus.done,
      categoryId: 'cat_family',
      createdAt: at(today.subtract(const Duration(days: 6)), 11),
      completedAt: at(today.subtract(const Duration(days: 5)), 17, 20),
    ),
    Todo(
      id: 't18',
      title: '整理 9 月上半月交易记录并归档截图',
      status: TodoStatus.done,
      categoryId: 'cat_stock',
      createdAt: at(today.subtract(const Duration(days: 7)), 21),
      completedAt: at(today.subtract(const Duration(days: 6)), 22, 10),
    ),
    Todo(
      id: 't19',
      title: '参加馆里数字化加工培训并签到',
      status: TodoStatus.done,
      categoryId: 'cat_work',
      dueAt: at(today.subtract(const Duration(days: 3)), 14),
      createdAt: at(today.subtract(const Duration(days: 6)), 8, 30),
      completedAt: at(today.subtract(const Duration(days: 3)), 16),
    ),
    Todo(
      id: 't20',
      title: '约师傅修厨房水龙头',
      status: TodoStatus.done,
      categoryId: 'cat_family',
      createdAt: at(today.subtract(const Duration(days: 9)), 12),
      completedAt: at(today.subtract(const Duration(days: 8)), 10, 15),
    ),
    // 待办补充
    Todo(
      id: 't21',
      title: '关注美联储 9 月议息会议结果',
      categoryId: 'cat_stock_plan',
      dueAt: at(today.add(const Duration(days: 5)), 2),
      createdAt: at(today, 8, 20),
    ),
    Todo(
      id: 't22',
      title: '把借阅登记表模板改成新格式',
      categoryId: 'cat_archive_lend',
      createdAt: at(today, 13, 10),
    ),
    // 已取消（归入看板「已完成」列底部）
    Todo(
      id: 't23',
      title: '报名周六的行业交流会（已改线上，不用去了）',
      status: TodoStatus.cancelled,
      categoryId: 'cat_work',
      createdAt: at(today.subtract(const Duration(days: 2)), 10),
      updatedAt: at(today.subtract(const Duration(days: 1)), 9),
    ),
  ];
  return [
    for (var i = 0; i < seeds.length; i++)
      seeds[i].copyWith(sortOrder: i, updatedAt: seeds[i].createdAt),
    // 过去 52 周的历史记录（日程可视化热力图/分布/趋势取数）
    ..._seedHistory(today),
  ];
}

/// 历史种子（日程可视化增量）：确定性伪随机（以天数做 hash），
/// 每次启动数据一致。约 55% 的日子有记录，每天 1-8 条，80% 已完成；
/// 近期未完成的排到未来一周，给日历留出拖拽对象。
List<Todo> _seedHistory(DateTime today) {
  const pool = <(String, String?)>[
    ('登记市民政局移交的文书档案', 'cat_archive_in'),
    ('核对 2025 年接收台账页码', 'cat_archive_in'),
    ('录入第三批退休干部档案信息', 'cat_archive_in'),
    ('扫描接收登记表并归档', 'cat_archive_in'),
    ('整理本月借阅登记本', 'cat_archive_lend'),
    ('催还基建档案两卷', 'cat_archive_lend'),
    ('更新借阅台账电子档', 'cat_archive_lend'),
    ('修复破损案卷并登记', 'cat_archive'),
    ('学习档案著录新国标 DA/T 18-2022', 'cat_archive'),
    ('库房温湿度记录周汇总', 'cat_archive'),
    ('清点 B 区密集架案卷', 'cat_archive'),
    ('复盘当日涨停板个股', 'cat_stock'),
    ('整理本周交易截图归档', 'cat_stock'),
    ('阅读券商晨会纪要', 'cat_stock'),
    ('更新持仓成本与盈亏表', 'cat_stock_position'),
    ('复盘宁德时代当日走势', 'cat_stock_position'),
    ('检查茅台止损线触发情况', 'cat_stock_position'),
    ('写下比亚迪加仓计划', 'cat_stock_plan'),
    ('梳理可转债打新日程', 'cat_stock_plan'),
    ('制定下周交易纪律清单', 'cat_stock_plan'),
    ('陪妈妈去人民医院复查', 'cat_family'),
    ('缴纳水电燃气费', 'cat_family'),
    ('预约家电清洗服务', 'cat_family'),
    ('给阳台绿植换土施肥', 'cat_family'),
    ('采购周末家庭聚餐食材', 'cat_family'),
    ('撰写季度工作总结初稿', 'cat_work'),
    ('整理科室会议纪要', 'cat_work'),
    ('准备周五例会汇报材料', 'cat_work'),
    ('更新年度重点工作台账', 'cat_work'),
    ('整理手机相册备份', null),
    ('清理邮箱订阅列表', null),
    ('记录本周读书进度', null),
  ];
  final todos = <Todo>[];
  for (var d = 364; d >= 1; d--) {
    final h = (d * 2654435761) % 100;
    if (h < 45) continue;
    final count = h < 70
        ? 1
        : h < 85
        ? 2
        : h < 93
        ? 3
        : h < 97
        ? 5
        : 8;
    final day = today.subtract(Duration(days: d));
    for (var k = 0; k < count; k++) {
      final item = pool[(d * 7 + k * 11) % pool.length];
      final created = DateTime(
        day.year,
        day.month,
        day.day,
        8 + (d + k * 3) % 12,
        (d * 17 + k * 29) % 60,
      );
      final done = (d + k) % 5 != 0;
      DateTime? completedAt;
      if (done) {
        var cd = day.add(Duration(days: (d + k * 2) % 3));
        if (cd.isAfter(today)) cd = today;
        completedAt = DateTime(
          cd.year,
          cd.month,
          cd.day,
          9 + (d + k * 5) % 12,
          (d * 31 + k * 7) % 60,
        );
      }
      DateTime? dueAt;
      if (done) {
        dueAt = DateTime(day.year, day.month, day.day, 18);
      } else if (d <= 14) {
        final fd = today.add(Duration(days: (d + k) % 7));
        dueAt = DateTime(fd.year, fd.month, fd.day, 9 + d % 9);
      }
      todos.add(
        Todo(
          id: 'th_${d}_$k',
          title: item.$1,
          status: done ? TodoStatus.done : TodoStatus.pending,
          priority: switch ((d + k) % 10) {
            0 => TodoPriority.high,
            1 || 2 => TodoPriority.medium,
            _ => TodoPriority.none,
          },
          dueAt: dueAt,
          categoryId: item.$2,
          source: (d + k) % 7 == 0 ? TodoSource.ai : TodoSource.manual,
          createdAt: created,
          completedAt: completedAt,
        ),
      );
    }
  }
  return todos;
}
