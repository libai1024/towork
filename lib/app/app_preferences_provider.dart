import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_toast.dart';
import '../data/local/app_preferences_store.dart';
import '../domain/settings/app_preferences.dart';
import 'local_database_provider.dart';

final appPreferencesStoreProvider = FutureProvider<AppPreferencesStore>(
  (ref) async =>
      SqliteAppPreferencesStore(await ref.watch(localDatabaseProvider.future)),
);
final activePreferencesStoreProvider = StateProvider<AppPreferencesStore?>(
  (ref) => null,
);
final appPreferencesSnapshotProvider = StateProvider<AppPreferences>(
  (ref) => const AppPreferences(),
);
final appPreferencesControllerProvider = Provider<AppPreferencesController>((
  ref,
) {
  var alive = true;
  ref.onDispose(() => alive = false);
  return AppPreferencesController(
    current: () => ref.read(appPreferencesSnapshotProvider),
    store: () => ref.read(activePreferencesStoreProvider),
    publish: (value) {
      if (alive) {
        ref.read(appPreferencesSnapshotProvider.notifier).state = value;
      }
    },
  );
});

/// Ordered partial updates read the latest committed revision, so unrelated
/// switches changed in quick succession cannot overwrite one another.
class AppPreferencesController {
  AppPreferencesController({
    required this.current,
    required this.store,
    required this.publish,
  });
  final AppPreferences Function() current;
  final AppPreferencesStore? Function() store;
  final void Function(AppPreferences) publish;
  Future<void> _pending = Future.value();

  Future<AppPreferences> save(
    Map<String, Object?> changes, {
    int? expectedVersion,
  }) {
    final patch = Map<String, Object?>.unmodifiable(changes);
    final result = _pending.then((_) async {
      final before = current();
      if (expectedVersion != null && before.version != expectedVersion) {
        throw const PreferenceFailure(PreferenceFailureCode.conflict);
      }
      final storage = store();
      final AppPreferences after;
      if (storage == null) {
        // Isolated UI fixtures only. Production bootstrap always binds a store.
        after = before.patch(patch, nextVersion: before.version + 1);
      } else {
        after = await storage.update(patch, expectedVersion: before.version);
      }
      publish(after);
      return after;
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

Future<bool> savePreferences(
  BuildContext context,
  WidgetRef ref,
  Map<String, Object?> changes,
) async {
  try {
    await ref.read(appPreferencesControllerProvider).save(changes);
    return true;
  } catch (error) {
    if (context.mounted) {
      AppToast.show(
        context,
        message:
            error is PreferenceFailure &&
                error.code == PreferenceFailureCode.conflict
            ? '设置已变化，请重新打开后再试'
            : '未能保存设置，原设置已保留，请重试',
      );
    }
    return false;
  }
}
