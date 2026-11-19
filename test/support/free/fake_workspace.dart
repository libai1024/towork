import 'package:towork/domain/settings/app_preferences.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';

/// Read-only fixture for profile/bootstrap tests; mutations are deliberately not simulated.
class EmptyWorkspaceStore implements WorkspaceCommandStore {
  @override
  Future<WorkspaceSnapshot> load() async => WorkspaceSnapshot([]);
  @override
  Stream<WorkspaceSnapshot> watch() => Stream.value(WorkspaceSnapshot([]));
  @override
  Future<WorkspaceReceipt> execute(WorkspaceCommand command) =>
      throw UnimplementedError();
  @override
  Future<WorkspaceReceipt> undo(
    String changesetId, {
    required String operationId,
  }) => throw UnimplementedError();
}

class FixturePreferencesStore implements AppPreferencesStore {
  AppPreferences value = const AppPreferences(version: 1);
  @override
  Future<AppPreferences> loadOrCreate({
    String legacyInputMode = 'voice',
  }) async => value;
  @override
  Future<AppPreferences> update(
    Map<String, Object?> changes, {
    required int expectedVersion,
  }) async => value = value.patch(changes, nextVersion: value.version + 1);
}
