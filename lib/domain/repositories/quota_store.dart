import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';

/// Local demo scenarios; no remote quota is consumed.
enum QuotaDemo { normal, high, limited, empty }

abstract class QuotaStore extends StateNotifier<QuotaState> {
  QuotaStore(super.state);
  QuotaState get snapshot => state;
  QuotaDemo get demo;
  void applyDemo(QuotaDemo demo);
  void dismissLimitEvent();
}
