import 'dart:async';

import 'package:towork/domain/update/app_update.dart';
import 'package:towork/domain/update/code_update.dart';

class FakeCodeUpdateGateway implements CodeUpdateGateway {
  CodeUpdateStatus info = const CodeUpdateStatus(supported: true);
  CodeUpdate? offer = CodeUpdate(
    version: '1',
    manifest: 'signed',
    size: 1024,
    url: Uri.parse('https://example.test/patch'),
  );
  int checks = 0, applications = 0, restarts = 0, cancels = 0;
  Object? applyError;
  Object? restartError = const UpdateFailure('restart');
  Completer<void>? transfer;
  void Function()? verifying;
  @override
  Future<CodeUpdateStatus> status() async => info;
  @override
  Future<CodeUpdate?> check() async {
    checks++;
    return offer;
  }

  @override
  Future<void> apply(
    CodeUpdate update, {
    required void Function(int) onProgress,
    required void Function() onVerifying,
  }) async {
    applications++;
    verifying = onVerifying;
    onProgress(update.size ~/ 2);
    if (applyError case final error?) throw error;
    if (transfer != null) await transfer!.future;
    onVerifying();
  }

  @override
  Future<void> restart() async {
    restarts++;
    if (restartError case final error?) throw error;
  }

  @override
  void cancel() {
    cancels++;
    if (transfer != null && !transfer!.isCompleted) {
      transfer!.completeError(const UpdateFailure('code_cancelled'));
    }
  }
}
