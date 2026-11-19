import '../../domain/models/models.dart';
import '../../domain/repositories/report_store.dart';
import '../seeds/report_seed.dart';

import 'dart:async';

import '../../domain/repositories/repository_error.dart';
import 'repository_validation.dart';

class ReportRepository extends ReportStore {
  ReportRepository({
    List<Report>? initial,
    DateTime Function()? clock,
    this.generationDelay = const Duration(seconds: 4),
    this.compose,
  }) : _clock = clock ?? DateTime.now,
       super(
         requireUniqueIds(
           initial ?? seedReports((clock ?? DateTime.now)()),
           (Report report) => report.id,
         ),
       );

  final DateTime Function() _clock;
  final Duration generationDelay;
  final Report Function(Report)? compose;

  int _seq = 100;
  final Map<String, Timer> _generationTimers = {};

  @override
  List<Report> get visible => state.where((e) => e.deletedAt == null).toList();

  @override
  Report? byId(String? id) {
    if (id == null) return null;
    for (final e in state) {
      if (e.id == id && e.deletedAt == null) return e;
    }
    return null;
  }

  @override
  void markRead(String id, {bool read = true}) {
    state = [for (final e in state) e.id == id ? e.copyWith(isRead: read) : e];
  }

  /// 软删除（可撤销）：返回被删报告，撤销时调用 [restore]。
  @override
  Report? softDelete(String id) {
    final target = byId(id);
    if (target == null) return null;
    final now = _clock();
    _generationTimers.remove(id)?.cancel();
    state = [
      for (final e in state)
        e.id == id
            ? e.copyWith(
                deletedAt: now,
                status: e.status == ReportStatus.generating
                    ? ReportStatus.failed
                    : e.status,
                failureReason: e.status == ReportStatus.generating
                    ? '生成已停止'
                    : e.failureReason,
              )
            : e,
    ];
    return target;
  }

  @override
  void restore(String id) {
    state = [
      for (final e in state) e.id == id ? e.copyWith(deletedAt: null) : e,
    ];
  }

  /// 手动生成：先插入「生成中」卡片，mock 4 秒后写入完整内容。
  @override
  Report startGeneration({
    required DateTime periodStart,
    required DateTime periodEnd,
    required ReportType type,
    required String periodLabel,
    required List<ReportCategoryRef> categories,
  }) {
    if (periodEnd.isBefore(periodStart)) {
      throw const RepositoryException(
        RepositoryErrorCode.invalidInput,
        '报告结束日期不能早于开始日期',
      );
    }
    final now = _clock();
    String id;
    do {
      id = 'r_gen_${_seq++}';
    } while (state.any((report) => report.id == id));
    final report = Report(
      id: id,
      type: type,
      title: '$periodLabel${_typeSuffix(type)}',
      periodLabel: periodLabel,
      periodStart: periodStart,
      periodEnd: periodEnd,
      summary: '',
      status: ReportStatus.generating,
      isRead: true,
      source: ReportSource.manual,
      categorySnapshot: categories,
      createdAt: now,
      model: 'k3',
    );
    state = [report, ...state];
    _scheduleCompletion(report.id);
    return report;
  }

  /// 重新生成 / 失败重试：保留 id 与 isRead，状态回 generating，4 秒后覆写内容。
  @override
  void regenerate(String id) {
    final target = byId(id);
    if (target == null) return;
    state = [
      for (final e in state)
        e.id == id
            ? e.copyWith(
                status: ReportStatus.generating,
                failureReason: null,
                incompleteSections: const [],
              )
            : e,
    ];
    _scheduleCompletion(id);
  }

  /// 停止生成：丢弃半成品，不留记录（§3.4）。
  @override
  void stopGeneration(String id) {
    final report = byId(id);
    if (report == null || report.status != ReportStatus.generating) return;
    _generationTimers.remove(id)?.cancel();
    state = state.where((e) => e.id != id).toList();
  }

  void _scheduleCompletion(String id) {
    _generationTimers.remove(id)?.cancel();
    _generationTimers[id] = Timer(generationDelay, () {
      _generationTimers.remove(id);
      if (!mounted) return;
      final report = byId(id);
      if (report == null || report.status != ReportStatus.generating) return;
      Report completed;
      try {
        completed = (compose ?? _composeCompleted)(report);
        if (completed.id != id || completed.status == ReportStatus.generating) {
          throw StateError('Invalid report generation result');
        }
      } catch (_) {
        completed = report.copyWith(
          status: ReportStatus.failed,
          failureReason: '报告生成失败，请重试',
        );
      }
      state = [for (final item in state) item.id == id ? completed : item];
    });
  }

  static String _typeSuffix(ReportType type) => switch (type) {
    ReportType.weekly => '周报',
    ReportType.monthly => '月报',
    ReportType.custom => '报告',
  };

  /// mock 的「AI 撰写」：按勾选分类拼一份真实感报告。
  Report _composeCompleted(Report base) {
    final cats = base.categorySnapshot;
    const done = 18;
    const created = 25;
    const rate = 83.0;
    const overdue = 1;
    const dataCount = 24;
    final titles = ['一步一步，都在往前', '稳稳推进的一段日子', '事不多，但都成了'];
    final title = titles[base.id.hashCode.abs() % titles.length];

    const categoryLines = <String, List<String>>{
      '炒股': ['复盘了本期走势，按纪律执行了一次调仓', '止损提醒已更新，现金仓位保持在舒适区'],
      '档案馆': ['接收登记按台账推进，新入库案卷当日完成编目', '借阅登记均已按期核销'],
      '家庭': ['缴费与体检安排都落了地', '给家里打了两次电话'],
      '工作': ['例行周报与台账按时提交', '项目推进到下一个节点'],
    };

    final buf = StringBuffer()
      ..writeln('## 本期概览')
      ..writeln(
        '这段时间把手头的事往前推了一截：完成待办 **$done** 项，完成率 **${rate.toInt()}%**，新增 **$created** 项。'
        '${cats.isEmpty ? '' : '范围覆盖${cats.map((e) => e.name).join('、')}。'}',
      );
    for (final cat in cats) {
      final lines = categoryLines[cat.name] ?? const ['本期的记录都已归档', '节奏平稳，没有积压'];
      buf
        ..writeln()
        ..writeln('## ${cat.name}');
      for (final line in lines) {
        buf.writeln('- $line');
      }
    }
    buf
      ..writeln()
      ..writeln('## 核心数据变动')
      ..writeln('| 指标 | 上期 | 本期 | 变动 |')
      ..writeln('| --- | --- | --- | --- |')
      ..writeln('| 档案接收(卷) | 18 | $dataCount | **+6** |')
      ..writeln('| 账户市值(元) | 98,750 | 101,200 | **+2.5%** |')
      ..writeln()
      ..writeln('## AI 观察与建议')
      ..writeln('这段时间的完成高峰集中在下午 3 点前——重要的事尽量约在上午，余量会更多。')
      ..writeln('逾期的尾巴不多，但都指向同一件家事，建议设个自动提醒一次清掉。')
      ..writeln()
      ..writeln('## 逾期与风险')
      ..writeln('- 「物业费」临近截止，建议本周内处理')
      ..writeln()
      ..writeln('## 下期待办')
      ..writeln('- 例行周报与台账提交 周三前')
      ..writeln('- 复盘本期交易并更新持仓表 周日晚');

    final now = _clock();
    return base.copyWith(
      title: title,
      summary: '完成率 ${rate.toInt()}% 完成 $done 项 逾期 $overdue 项',
      status: ReportStatus.ready,
      failureReason: null,
      contentMarkdown: buf.toString().trimRight(),
      stats: const ReportStats(
        completionRate: rate,
        doneCount: done,
        createdCount: created,
        overdueCount: overdue,
        dataRowCount: dataCount,
        dataRowUnit: '卷',
        completionRateDelta: 2,
        doneCountDelta: 1,
        dataRowNote: '接收 2 批',
      ),
      readingMinutes: 2,
      generatedAt: now,
    );
  }

  @override
  void dispose() {
    for (final timer in _generationTimers.values) {
      timer.cancel();
    }
    _generationTimers.clear();
    super.dispose();
  }
}
