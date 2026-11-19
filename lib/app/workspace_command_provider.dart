import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/workspace_command_store.dart';
import '../domain/workspace/workspace_commands.dart';
import 'local_database_provider.dart';

/// Shared persistence boundary for both future manual UI adapters and Agent tools.
/// The legacy synchronous demo stores are not silently backed by async writes.
final workspaceCommandStoreProvider = FutureProvider<WorkspaceCommandStore>((
  ref,
) async {
  return SqliteWorkspaceCommandStore(
    await ref.watch(localDatabaseProvider.future),
  );
});
