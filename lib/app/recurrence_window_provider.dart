import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_workspace_session.dart';
import 'recurrence_window.dart';
import 'workspace_clock.dart';

final recurrenceWindowProvider = Provider<RecurrenceWindow?>((ref) {
  final session = ref.watch(localWorkspaceSessionProvider);
  if (session == null) return null;
  final worker = RecurrenceWindow(
    session,
    clock: ref.watch(workspaceNowProvider),
  );
  final lifecycle = _WindowLifecycle(worker, WidgetsBinding.instance);
  ref.onDispose(() {
    lifecycle.dispose();
    worker.dispose();
  });
  return worker;
});

class _WindowLifecycle with WidgetsBindingObserver {
  _WindowLifecycle(this.worker, this.binding) {
    binding.addObserver(this);
    final state = binding.lifecycleState;
    if (state != null) didChangeAppLifecycleState(state);
  }
  final RecurrenceWindow worker;
  final WidgetsBinding binding;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => worker.setActive(
    state == AppLifecycleState.resumed || state == AppLifecycleState.inactive,
  );
  void dispose() => binding.removeObserver(this);
}
