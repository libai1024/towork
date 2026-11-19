import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用层发起页面跳转的出口。应用层（通知、快捷唤醒等）不认识路由器，
/// 只提交「去哪」；外壳层的路由器启动后接管。路由器就绪前的请求会
/// 暂存并在接管时按序送达，冷启动点通知不会丢跳转。
class AppNavigationRequests {
  void Function(String location)? _handler;
  final _pending = <String>[];

  void go(String location) {
    final handler = _handler;
    if (handler == null) {
      _pending.add(location);
      return;
    }
    handler(location);
  }

  void attach(void Function(String location) handler) {
    _handler = handler;
    final queued = List<String>.of(_pending);
    _pending.clear();
    for (final location in queued) {
      handler(location);
    }
  }

  void detach(void Function(String location) handler) {
    if (identical(_handler, handler)) _handler = null;
  }
}

final appNavigationRequestsProvider = Provider<AppNavigationRequests>(
  (ref) => AppNavigationRequests(),
);
