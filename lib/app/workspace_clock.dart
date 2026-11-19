import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable wall time shared by time-dependent workspace projections.
final workspaceNowProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final workspaceClockProvider =
    StateNotifierProvider.autoDispose<WorkspaceClock, WorkspaceTime>(
      (ref) => WorkspaceClock(now: ref.watch(workspaceNowProvider)),
    );

class WorkspaceTime {
  const WorkspaceTime({required this.now, required this.isActive});
  final DateTime now;
  final bool isActive;
}

/// Invalidates relative dates at minute boundaries and after app resumption.
/// Only exists while a time-dependent view is listening to its provider.
class WorkspaceClock extends StateNotifier<WorkspaceTime>
    with WidgetsBindingObserver {
  factory WorkspaceClock({DateTime Function()? now, WidgetsBinding? binding}) =>
      WorkspaceClock._(now ?? DateTime.now, binding ?? WidgetsBinding.instance);

  WorkspaceClock._(this._now, this._binding)
    : super(
        WorkspaceTime(
          now: _now(),
          isActive: _isActive(_binding.lifecycleState),
        ),
      ) {
    _binding.addObserver(this);
    _schedule();
  }

  final DateTime Function() _now;
  final WidgetsBinding _binding;
  Timer? _timer;

  static bool _isActive(AppLifecycleState? lifecycle) =>
      lifecycle == null ||
      lifecycle == AppLifecycleState.resumed ||
      lifecycle == AppLifecycleState.inactive;

  void refresh() {
    if (!mounted) return;
    state = WorkspaceTime(now: _now(), isActive: state.isActive);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!state.isActive) return;
    final now = state.now;
    final elapsedInMinute = Duration(
      seconds: now.second,
      milliseconds: now.millisecond,
      microseconds: now.microsecond,
    );
    _timer = Timer(const Duration(minutes: 1) - elapsedInMinute, refresh);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    this.state = WorkspaceTime(now: _now(), isActive: _isActive(state));
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _binding.removeObserver(this);
    super.dispose();
  }
}
