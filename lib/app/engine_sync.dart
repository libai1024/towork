import 'dart:async';

import '../data/local/agent_run_store.dart';
import '../data/local/app_database.dart';
import '../domain/assist/quick_assist.dart';

/// 让同一进程里的两个界面引擎看到彼此的提交。
///
/// 主应用和快捷面板各开一条数据库连接。一方提交后，另一方的监听查询
/// 不会自己醒来。`PRAGMA data_version` 只在别的连接提交后变化，所以回到
/// 前台时比较它：变了就让所有监听查询重跑，并重读会话。另一个引擎还
/// 活着时按 [interval] 继续比较，直到它退出。
///
/// 顺带处理两件只有此时才能安全做的事：没有别的引擎、自己也不在生成
/// 时，把遗留的「生成中」运行标为中断；取走快捷面板留下的去向。
class EngineSync {
  EngineSync({
    required this.db,
    required this.peers,
    required this.refresh,
    required this.busy,
    required this.onHandoff,
    this.interval = const Duration(seconds: 2),
  });

  final AppDatabase db;
  final EnginePeers peers;

  /// 重读会话投影。待办和分类由监听查询自己更新。
  final Future<void> Function() refresh;

  /// 本引擎是否正在生成或等待用户确认。此时不清理「生成中」的运行。
  final bool Function() busy;
  final void Function(AssistHandoff handoff) onHandoff;
  final Duration interval;

  int? _seen;
  Timer? _timer;
  bool _active = false;
  bool _checking = false;
  bool _again = false;
  bool _disposed = false;
  bool _needsRefresh = false;
  AssistHandoff? _pendingHandoff;

  /// 界面在前台时为 true。回到前台立即比较一次。
  void setActive(bool active) {
    _active = active;
    _timer?.cancel();
    _timer = null;
    if (active) unawaited(check());
  }

  Future<int> _dataVersion() async {
    final row = await db.customSelect('PRAGMA data_version').getSingle();
    return row.data.values.first as int;
  }

  /// 比较一次。已经在比较时只记下「再来一次」，不并发执行。
  Future<void> check() async {
    if (_disposed) return;
    if (_checking) {
      _again = true;
      return;
    }
    _checking = true;
    var poll = false;
    try {
      do {
        _again = false;
        final version = await _dataVersion();
        final changed = _seen != null && version != _seen;
        final others = await peers.othersAlive();
        poll = others;
        var recovered = 0;
        if (!others && !busy()) {
          recovered = await SqliteAgentRunStore(db)
              .interruptAbandonedGenerations();
        }
        if (_disposed) return;
        _needsRefresh = _needsRefresh || changed || recovered > 0;
        if (_needsRefresh) {
          db.markTablesUpdated(db.allTables);
          await refresh();
          _needsRefresh = false;
        }
        _seen = version;
        final handoff = _pendingHandoff ?? await peers.takeHandoff();
        _pendingHandoff = handoff;
        if (_disposed) return;
        if (handoff != null) {
          // 首次比较也可能收到启动期间产生的会话。刷新成功后才消费交接。
          db.markTablesUpdated(db.allTables);
          await refresh();
          if (_disposed) return;
          onHandoff(handoff);
          _pendingHandoff = null;
        }
      } while (_again && !_disposed);
    } catch (_) {
      // 保留未完成的刷新和交接，前台继续重试。
      poll = true;
    } finally {
      _checking = false;
      _timer?.cancel();
      _timer = poll && _active && !_disposed ? Timer(interval, check) : null;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
