import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/update/code_update_host.dart';
import '../chat/chat_view_model.dart';
import '../local_workspace_session.dart';

/// Editors register live predicates so a second engine's draft survives a
/// requested update. The native restart waits for every activity to be ready.
final updateRestartGuardsProvider = Provider<Set<bool Function()>>((ref) => {});

final codeUpdateHostProvider = Provider<CodeUpdateHost>((ref) {
  final guards = ref.watch(updateRestartGuardsProvider);
  final host = CodeUpdateHost(
    () =>
        !ref.read(chatViewModelProvider).isGenerating &&
        !(ref.read(localWorkspaceSessionProvider)?.automaticWorkHeld ?? true) &&
        guards.every((canRestart) => canRestart()),
  );
  ref.onDispose(host.dispose);
  return host;
});
