import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/update/release_history_source.dart';
import '../../domain/update/release_history.dart';

final releaseHistoryProvider = StreamProvider<List<ReleaseHistoryEntry>>((
  ref,
) async* {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  final bundled = await bundledReleaseHistory();
  yield bundled;
  try {
    final remote = await onlineReleaseHistory(dio);
    final ids = {for (final entry in remote) entry.id};
    if (bundled.every((entry) => ids.contains(entry.id))) yield remote;
  } on DioException {
    // The bundled history remains available offline.
  } on FormatException {
    // Ignore malformed server content.
  }
});
