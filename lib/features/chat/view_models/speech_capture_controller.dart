import 'package:towork/l10n/strings.dart';

import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/speech/speech_input.dart';
import '../../../domain/workspace/workspace_commands.dart';

enum SpeechPhase {
  idle,
  requesting,
  starting,
  recording,
  finalizing,
  pending,
  submitting,
  sent,
  draft,
  cancelled,
}

class SpeechCaptureState {
  const SpeechCaptureState({
    this.phase = SpeechPhase.idle,
    this.captureId,
    this.text = '',
    this.problem,
    this.capabilities,
  });
  final SpeechPhase phase;
  final String? captureId;
  final String text;
  final String? problem;
  final SpeechCapabilities? capabilities;
}

/// PCM updates only repaint the level meter, independently of transcription.
class SpeechMeter extends ChangeNotifier {
  List<double> samples = const [];

  void reset() {
    samples = const [];
    notifyListeners();
  }

  void push(double level) {
    samples = [...samples.skip(samples.length == 9 ? 1 : 0), level];
    notifyListeners();
  }
}

/// One UI capture owns one native session. Only genuine finals are eligible for
/// delayed auto-send. No connectivity event can replay a retained draft.
class SpeechCaptureController extends StateNotifier<SpeechCaptureState> {
  SpeechCaptureController({
    required this.input,
    required this.hasNetworkRoute,
    required this.submit,
    required this.cancelSubmission,
    this.autoSendDelay = const Duration(seconds: 2),
    this.finalTimeout = const Duration(seconds: 5),
    this.startTimeout = const Duration(seconds: 8),
    this.maxRecording = const Duration(seconds: 60),
    bool waitForRelease = false,
    String Function()? newId,
  }) : _sendAllowed = !waitForRelease,
       _newId = newId ?? (() => newWorkspaceId('speech')),
       super(const SpeechCaptureState()) {
    _subscription = input.events.listen(
      _event,
      onError: (Object _) => _fail(strings.voiceInputInterrupted),
    );
  }
  final SpeechInput input;
  final Future<bool> Function() hasNetworkRoute;
  final Future<bool> Function(String text, String inputId) submit;
  final void Function() cancelSubmission;
  final Duration autoSendDelay, finalTimeout, startTimeout, maxRecording;
  final String Function() _newId;
  StreamSubscription<SpeechEvent>? _subscription;
  Timer? _timer, _limit;
  String? _active;
  bool _acceptedFinal = false;
  bool _finishAsDraft = false;
  final levels = SpeechMeter();
  bool _sendAllowed;
  Future<void> _native = Future.value();
  SpeechCaptureState get snapshot => state;
  bool _current(String id) => mounted && _active == id;
  bool get _receiving => {
    SpeechPhase.starting,
    SpeechPhase.recording,
    SpeechPhase.finalizing,
  }.contains(state.phase);
  void _publish(
    SpeechPhase phase, {
    String? text,
    String? problem,
    SpeechCapabilities? capabilities,
  }) {
    if (!mounted) return;
    state = SpeechCaptureState(
      phase: phase,
      captureId: state.captureId,
      text: text ?? state.text,
      problem: problem,
      capabilities: capabilities ?? state.capabilities,
    );
  }

  void _clearTimers() {
    _timer?.cancel();
    _limit?.cancel();
  }

  // Serialize native setup and cleanup, including a late permission answer.
  Future<void> _enqueue(Future<void> Function() work) {
    final next = _native.then((_) => work());
    _native = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> start({String? locale, bool onDevice = false}) async {
    if (!mounted || _active != null) return;
    final recognitionLocale = locale ?? speechLocale;
    final id = _newId();
    _active = id;
    _acceptedFinal = false;
    _finishAsDraft = false;
    levels.reset();
    state = SpeechCaptureState(phase: SpeechPhase.requesting, captureId: id);
    try {
      await _enqueue(() async {
        if (!_current(id)) return;
        final capabilities = await input.prepare(recognitionLocale);
        if (!_current(id)) return;
        _publish(SpeechPhase.requesting, capabilities: capabilities);
        if (!capabilities.available) {
          throw const SpeechFailure(SpeechFailureCode.unavailable);
        }
        if (!capabilities.authorized) {
          throw const SpeechFailure(SpeechFailureCode.permissionDenied);
        }
        if (onDevice && !capabilities.onDeviceSupported) {
          throw const SpeechFailure(SpeechFailureCode.onDeviceUnavailable);
        }
        if (capabilities.locales.isNotEmpty &&
            !capabilities.locales.any(
              (l) =>
                  l.replaceAll('_', '-').toLowerCase() ==
                  recognitionLocale.toLowerCase(),
            )) {
          throw const SpeechFailure(SpeechFailureCode.localeUnavailable);
        }
        _publish(SpeechPhase.starting);
        _timer = Timer(startTimeout, () {
          if (_current(id) && state.phase == SpeechPhase.starting) {
            _fail(strings.couldntStartVoiceInput);
          }
        });
        await input.start(id, locale: recognitionLocale, onDevice: onDevice);
      });
    } catch (error) {
      if (_current(id)) _fail(speechErrorMessage(error));
    }
  }

  void _event(SpeechEvent event) {
    if (!_current(event.captureId)) return;
    switch (event.kind) {
      case SpeechEventKind.level:
        if (state.phase == SpeechPhase.recording) {
          levels.push(event.level);
        }
      case SpeechEventKind.listening:
        if (state.phase != SpeechPhase.starting) return;
        _timer?.cancel();
        _publish(SpeechPhase.recording);
        _limit = Timer(maxRecording, () => unawaited(stop(released: false)));
      case SpeechEventKind.partial:
        if (_receiving && !_acceptedFinal) {
          if (event.text.length > 20000) {
            _fail(strings.transcriptIsTooLongSplitItInto);
            return;
          }
          _publish(state.phase, text: event.text);
        }
      case SpeechEventKind.finalResult:
        if (!_receiving || _acceptedFinal) return;
        _acceptedFinal = true;
        _clearTimers();
        if (event.text.trim().isEmpty) {
          _fail(strings.couldntHearThatTryAgain);
          return;
        }
        if (event.text.length > 20000) {
          _fail(strings.transcriptIsTooLongSplitItInto);
          return;
        }
        if (_finishAsDraft) {
          _active = null;
          _cleanup(event.captureId);
          _publish(SpeechPhase.draft, text: event.text.trim());
          return;
        }
        _publish(SpeechPhase.pending, text: event.text.trim());
        if (_sendAllowed) {
          _timer = Timer(
            autoSendDelay,
            () => unawaited(_send(event.captureId)),
          );
        }
      case SpeechEventKind.ended:
        if (_receiving) _waitForFinal();
      case SpeechEventKind.error:
        if (state.phase != SpeechPhase.submitting) {
          _fail(
            speechErrorMessage(
              SpeechFailure(event.error ?? SpeechFailureCode.interrupted),
            ),
          );
        }
    }
  }

  void _waitForFinal() {
    if (state.phase == SpeechPhase.finalizing) return;
    _clearTimers();
    _publish(SpeechPhase.finalizing);
    final id = _active!;
    _timer = Timer(finalTimeout, () {
      if (_current(id)) _fail(strings.recognitionTimedOutTryAgain);
    });
  }

  Future<void> stop({bool released = true, bool forEditing = false}) async {
    if (forEditing) _finishAsDraft = true;
    final wasHeld = released && !_sendAllowed;
    if (released) _sendAllowed = true;
    final id = _active;
    if (id == null) return;
    if (_finishAsDraft && state.phase == SpeechPhase.pending) {
      cancel(keepDraft: true);
      return;
    }
    if (wasHeld && state.phase == SpeechPhase.pending) {
      _timer = Timer(autoSendDelay, () => unawaited(_send(id)));
      return;
    }
    if (state.phase == SpeechPhase.requesting ||
        state.phase == SpeechPhase.starting) {
      cancel(); // Releasing before capture starts must not start a later recording.
      return;
    }
    if (state.phase != SpeechPhase.recording) return;
    _waitForFinal();
    try {
      await _enqueue(() => input.stop(id));
    } catch (error) {
      if (_current(id)) _fail(speechErrorMessage(error));
    }
  }

  Future<void> _send(String id) async {
    if (!_current(id) || state.phase != SpeechPhase.pending) return;
    try {
      // connectivity_plus 在部分 ROM（如部分华为机型）会把可用网络
      // 误报为 none；预检只作提示信号，不再拦截发送——真实的网络
      // 失败由请求自身落为可重试的错误，不会丢转写。
      await hasNetworkRoute();
      if (!_current(id) || state.phase != SpeechPhase.pending) return;
      _publish(SpeechPhase.submitting);
      final accepted = await submit(state.text, id);
      if (!_current(id)) return;
      _active = null;
      _cleanup(id);
      _publish(
        accepted ? SpeechPhase.sent : SpeechPhase.draft,
        problem: accepted ? null : strings.couldntSendYourTextIsSaved,
      );
    } catch (_) {
      if (_current(id)) _fail(strings.couldntSendYourTextIsSaved);
    }
  }

  void _cleanup(String id) {
    unawaited(_enqueue(() => input.cancel(id)).catchError((Object _) {}));
  }

  void _fail(String problem) {
    if (!mounted) return;
    final id = _active;
    if (id == null) return;
    _active = null;
    _clearTimers();
    _cleanup(id);
    _publish(SpeechPhase.draft, problem: problem);
  }

  void cancel({bool keepDraft = false}) {
    if (!mounted) return;
    final id = _active;
    _active = null;
    _clearTimers();
    if (state.phase == SpeechPhase.submitting) cancelSubmission();
    if (id != null) _cleanup(id);
    // keepDraft 是用户主动「转为文字修改」，不带提示；具体反馈由调用方给出。
    _publish(
      keepDraft ? SpeechPhase.draft : SpeechPhase.cancelled,
      text: keepDraft ? state.text : '',
    );
  }

  @override
  void dispose() {
    cancel();
    unawaited(_subscription?.cancel());
    levels.dispose();
    super.dispose();
  }
}

String speechErrorMessage(Object error) => switch (error) {
  SpeechFailure(code: SpeechFailureCode.permissionDenied) =>
    strings.allowMicrophoneAccessInSystemSettings,
  SpeechFailure(code: SpeechFailureCode.localeUnavailable) =>
    strings.selectedLanguageIsUnavailable,
  SpeechFailure(code: SpeechFailureCode.onDeviceUnavailable) =>
    strings.thisRecognizerDoesNotSupportOnDevice,
  SpeechFailure(code: SpeechFailureCode.noResult) =>
    strings.couldntHearThatTryAgain,
  SpeechFailure(code: SpeechFailureCode.network) =>
    strings.couldntConnectToSpeechService,
  SpeechFailure(code: SpeechFailureCode.busy) => strings.microphoneInUse,
  SpeechFailure(code: SpeechFailureCode.interrupted) =>
    strings.recordingInterrupted,
  _ => strings.voiceInputUnavailable,
};
