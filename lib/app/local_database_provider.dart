import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/local/app_database.dart';

/// One application-owned connection shared by settings and business modules.
final localDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final db = AppDatabase.background(
    File('${directory.path}/towork-free.sqlite'),
  );
  ref.onDispose(() => unawaited(db.close()));
  return db;
});
