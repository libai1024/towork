import '../../domain/models/models.dart';
import '../../domain/repositories/quota_store.dart';
import '../seeds/quota_seed.dart';

class QuotaRepository extends QuotaStore {
  /// 默认零用量（真实状态：尚无调用记录），不再预置演示数据；
  /// 各演示态仅供开发与测试经 [applyDemo] 切换。
  QuotaRepository() : super(seedQuotaState(QuotaDemo.empty));

  QuotaDemo _demo = QuotaDemo.empty;
  @override
  QuotaDemo get demo => _demo;

  /// 切换演示态；重新选「触顶」时复位 dismissed，新 403 会再次出现（§5）。
  @override
  void applyDemo(QuotaDemo demo) {
    _demo = demo;
    state = seedQuotaState(demo);
  }

  /// 「知道了」：横幅本次会话内不再出现（§5）。
  @override
  void dismissLimitEvent() {
    if (state.limitEvent == null) return;
    state = QuotaState(
      bars: state.bars,
      limitEvent: state.limitEvent,
      limitEventDismissed: true,
    );
  }
}
