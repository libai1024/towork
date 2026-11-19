import 'dart:async';

import 'model_gateway.dart';

/// Checks permission to send model content to one exact HTTPS origin.
typedef AuthorizeModelTransmission = Future<void> Function(
  String origin,
  String provider,
);

Future<void> authorizeModelRequest(
  AuthorizeModelTransmission authorize,
  ModelProfile profile,
  ModelCancellation? cancellation,
) async {
  if (cancellation?.isCancelled ?? false) {
    throw const ModelFailure(ModelFailureCode.cancelled);
  }
  final pending = authorize(
    profile.completionsUri.origin,
    profile.descriptor.label,
  );
  if (cancellation == null) return pending;
  final stopped = Completer<void>();
  final detach = cancellation.onCancel(stopped.complete);
  try {
    await Future.any([pending, stopped.future]);
    if (cancellation.isCancelled) {
      throw const ModelFailure(ModelFailureCode.cancelled);
    }
  } finally {
    detach();
  }
}
