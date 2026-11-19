import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/settings/local_profile.dart';
import 'local_database_provider.dart';

final localProfileStoreProvider = FutureProvider<LocalProfileStore>(
  (ref) => ref.watch(localDatabaseProvider.future),
);

/// UI projection, replaced only after a successful read or committed command.
/// main's bootstrap hydrates it; existing isolated demo fixtures can omit it.
final localProfileSnapshotProvider = StateProvider<LocalProfile?>(
  (ref) => null,
);
