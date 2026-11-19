enum SpeechFailureCode {
  permissionDenied,
  unavailable,
  localeUnavailable,
  onDeviceUnavailable,
  interrupted,
  noResult,
  network,
  busy,
  startFailed,
  finalTimeout,
  tooLong,
}

class SpeechFailure implements Exception {
  const SpeechFailure(this.code);
  final SpeechFailureCode code;
  @override
  String toString() => 'SpeechFailure(${code.name})';
}

class SpeechCapabilities {
  SpeechCapabilities({
    required this.available,
    required this.authorized,
    required Iterable<String> locales,
    required this.onDeviceSupported,
  }) : locales = List.unmodifiable(locales);
  final bool available, authorized;

  /// Empty means the platform did not enumerate languages, not confirmed support.
  final List<String> locales;
  final bool onDeviceSupported;
}

enum SpeechEventKind { listening, partial, finalResult, ended, error, level }

class SpeechEvent {
  const SpeechEvent(
    this.captureId,
    this.kind, {
    this.text = '',
    this.error,
    this.level = 0,
  });
  final String captureId, text;
  final double level;
  final SpeechEventKind kind;
  final SpeechFailureCode? error;
}

abstract interface class SpeechInput {
  Stream<SpeechEvent> get events;
  Future<SpeechCapabilities> inspect(String locale);
  Future<SpeechCapabilities> prepare(String locale);
  Future<void> start(
    String captureId, {
    required String locale,
    required bool onDevice,
  });
  Future<void> stop(String captureId);
  Future<void> cancel(String captureId);
  Future<void> openSettings();
}
