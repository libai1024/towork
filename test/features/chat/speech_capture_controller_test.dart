import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/domain/speech/speech_input.dart';
import 'package:towork/features/chat/view_models/speech_capture_controller.dart';

import '../../support/free/fake_speech.dart';

void main() {
  late FakeSpeechInput input;
  late SpeechCaptureController vm;
  late List<(String, String)> submissions;
  bool online = true, accept = true;
  int cancelCount = 0, sequence = 0;
  Completer<bool>? networkGate, submitGate;
  setUp(() {
    input = FakeSpeechInput();
    submissions = [];
    online = true;
    accept = true;
    cancelCount = 0;
    sequence = 0;
    networkGate = null;
    submitGate = null;
  });
  tearDown(() async {
    await input.bus.close();
  });
  void run(void Function(FakeAsync) body, {bool held = false}) {
    fakeAsync((clock) {
      vm = SpeechCaptureController(
        input: input,
        waitForRelease: held,
        hasNetworkRoute: () async =>
            networkGate == null ? online : await networkGate!.future,
        submit: (text, id) async {
          submissions.add((text, id));
          return submitGate == null ? accept : await submitGate!.future;
        },
        cancelSubmission: () => cancelCount++,
        newId: () => 'capture_${++sequence}',
      );
      try {
        body(clock);
      } finally {
        vm.dispose();
        clock.flushMicrotasks();
      }
    });
  }

  void start(FakeAsync clock) {
    unawaited(vm.start());
    clock.flushMicrotasks();
  }

  void finalResult(String id, [String text = '明天开会']) =>
      input.emit(id, SpeechEventKind.finalResult, text: text);

  test(
    'final during a hold waits for release and a full cancellation window',
    () {
      run((clock) {
        start(clock);
        finalResult('capture_1');
        clock.elapse(const Duration(seconds: 10));
        expect(submissions, isEmpty);
        unawaited(vm.stop());
        clock.flushMicrotasks();
        clock.elapse(const Duration(milliseconds: 1999));
        expect(submissions, isEmpty);
        clock.elapse(const Duration(milliseconds: 1));
        expect(submissions, [('明天开会', 'capture_1')]);
      }, held: true);
    },
  );

  test('recording limit stops the mic without releasing a held command', () {
    run((clock) {
      start(clock);
      clock.elapse(const Duration(seconds: 60));
      expect(input.stops, ['capture_1']);
      finalResult('capture_1');
      clock.elapse(const Duration(seconds: 10));
      expect(submissions, isEmpty);
      unawaited(vm.stop());
      clock.elapse(const Duration(seconds: 2));
      expect(submissions, [('明天开会', 'capture_1')]);
    }, held: true);
  });

  test(
    'genuine final auto-sends once after cancel window using capture identity',
    () {
      run((clock) {
        start(clock);
        expect(vm.snapshot.phase, SpeechPhase.recording);
        input.emit('capture_1', SpeechEventKind.partial, text: '明天');
        clock.elapse(const Duration(seconds: 1));
        expect(submissions, isEmpty);
        finalResult('capture_1');
        finalResult('capture_1', '重复回调');
        clock.elapse(const Duration(milliseconds: 1999));
        expect(submissions, isEmpty);
        clock.elapse(const Duration(milliseconds: 1));
        expect(submissions, [('明天开会', 'capture_1')]);
        expect(vm.snapshot.phase, SpeechPhase.sent);
        finalResult('capture_1');
        clock.flushMicrotasks();
        expect(submissions, hasLength(1));
      });
    },
  );
  test('stop waits for real final, never promotes a partial at timeout', () {
    run((clock) {
      start(clock);
      input.emit('capture_1', SpeechEventKind.partial, text: '未完成');
      unawaited(vm.stop());
      clock.flushMicrotasks();
      expect(input.stops, ['capture_1']);
      expect(vm.snapshot.phase, SpeechPhase.finalizing);
      clock.elapse(const Duration(seconds: 5));
      expect(vm.snapshot.phase, SpeechPhase.draft);
      expect(vm.snapshot.text, '未完成');
      finalResult('capture_1');
      clock.elapse(const Duration(seconds: 3));
      expect(submissions, isEmpty);
    });
  });
  test('silence end then final can send without a second user action', () {
    run((clock) {
      start(clock);
      input.emit('capture_1', SpeechEventKind.ended);
      finalResult('capture_1');
      clock.elapse(const Duration(seconds: 2));
      expect(vm.snapshot.phase, SpeechPhase.sent);
    });
  });
  test('cancel during the preview window invalidates final and timer', () {
    run((clock) {
      start(clock);
      finalResult('capture_1');
      vm.cancel();
      finalResult('capture_1');
      clock.elapse(const Duration(seconds: 10));
      expect(submissions, isEmpty);
      expect(vm.snapshot.phase, SpeechPhase.cancelled);
      expect(input.cancels, contains('capture_1'));
    });
  });
  test('cancel pending permission never begins a late microphone capture', () {
    run((clock) {
      input.prepareGate = Completer();
      start(clock);
      vm.cancel();
      input.prepareGate!.complete(input.capabilities);
      clock.flushMicrotasks();
      expect(input.starts, isEmpty);
      expect(submissions, isEmpty);
    });
  });
  test('old native capture callbacks cannot contaminate a new session', () {
    run((clock) {
      start(clock);
      vm.cancel();
      start(clock);
      finalResult('capture_1', '旧删除指令');
      input.emit(
        'capture_1',
        SpeechEventKind.error,
        error: SpeechFailureCode.interrupted,
      );
      expect(vm.snapshot.phase, SpeechPhase.recording);
      expect(vm.snapshot.text, isEmpty);
      finalResult('capture_2', '新指令');
      clock.elapse(const Duration(seconds: 2));
      expect(submissions, [('新指令', 'capture_2')]);
    });
  });
  test('denied permission never starts recognition', () {
    run((clock) {
      input.capabilities = SpeechCapabilities(
        available: true,
        authorized: false,
        locales: [],
        onDeviceSupported: false,
      );
      start(clock);
      expect(vm.snapshot.phase, SpeechPhase.draft);
      expect(input.starts, isEmpty);
      expect(vm.snapshot.problem, contains('权限'));
    });
  });
  test(
    'on-device mode never falls back to an unsupported remote recognizer',
    () {
      run((clock) {
        input.capabilities = SpeechCapabilities(
          available: true,
          authorized: true,
          locales: [],
          onDeviceSupported: false,
        );
        unawaited(vm.start(onDevice: true));
        clock.flushMicrotasks();
        expect(input.starts, isEmpty);
        expect(vm.snapshot.problem, contains('不会自动切换'));
      });
    },
  );
  test('known missing locale cannot silently use another language', () {
    run((clock) {
      input.capabilities = SpeechCapabilities(
        available: true,
        authorized: true,
        locales: ['en-US'],
        onDeviceSupported: true,
      );
      start(clock);
      expect(input.starts, isEmpty);
      expect(vm.snapshot.problem, contains('所选语言'));
    });
  });
  test(
    'connectivity misreport submits anyway; reconnecting does not replay',
    () {
      run((clock) {
        online = false;
        start(clock);
        finalResult('capture_1');
        clock.elapse(const Duration(seconds: 2));
        // 预检误报不再拦截：照常提交一次，失败由请求层落错。
        expect(submissions, hasLength(1));
        clock.elapse(const Duration(minutes: 1));
        expect(submissions, hasLength(1), reason: '不重复提交');
      });
    },
  );
  test(
    'cancel while network preflight is pending prevents late submission',
    () {
      run((clock) {
        networkGate = Completer();
        start(clock);
        finalResult('capture_1');
        clock.elapse(const Duration(seconds: 2));
        vm.cancel();
        networkGate!.complete(true);
        clock.flushMicrotasks();
        expect(submissions, isEmpty);
      });
    },
  );
  test('cancel after handoff cancels Agent request, never claims rollback', () {
    run((clock) {
      submitGate = Completer();
      start(clock);
      finalResult('capture_1');
      clock.elapse(const Duration(seconds: 2));
      expect(vm.snapshot.phase, SpeechPhase.submitting);
      vm.cancel();
      submitGate!.complete(true);
      clock.flushMicrotasks();
      expect(cancelCount, 1);
      expect(vm.snapshot.phase, SpeechPhase.cancelled);
      expect(submissions, hasLength(1));
    });
  });
  test(
    'error arriving before auto-send retains draft and suppresses the final',
    () {
      run((clock) {
        start(clock);
        finalResult('capture_1');
        input.emit(
          'capture_1',
          SpeechEventKind.error,
          error: SpeechFailureCode.network,
        );
        clock.elapse(const Duration(seconds: 5));
        expect(submissions, isEmpty);
        expect(vm.snapshot.text, '明天开会');
        expect(vm.snapshot.phase, SpeechPhase.draft);
      });
    },
  );
  test('native start timeout exposes a recoverable error', () {
    run((clock) {
      input.startListening = false;
      start(clock);
      clock.elapse(const Duration(seconds: 8));
      expect(vm.snapshot.phase, SpeechPhase.draft);
      expect(input.cancels, contains('capture_1'));
    });
  });
  test(
    'recording duration limit stops audio but does not send partial text',
    () {
      run((clock) {
        start(clock);
        input.emit('capture_1', SpeechEventKind.partial, text: '很长的录音');
        clock.elapse(const Duration(seconds: 60));
        expect(input.stops, ['capture_1']);
        clock.elapse(const Duration(seconds: 5));
        expect(submissions, isEmpty);
        expect(vm.snapshot.phase, SpeechPhase.draft);
      });
    },
  );
  test('blank final is not an accepted input', () {
    run((clock) {
      start(clock);
      finalResult('capture_1', '  ');
      clock.elapse(const Duration(seconds: 3));
      expect(submissions, isEmpty);
      expect(vm.snapshot.phase, SpeechPhase.draft);
    });
  });
  test('rejected input commit retains text for manual retry', () {
    run((clock) {
      accept = false;
      start(clock);
      finalResult('capture_1');
      clock.elapse(const Duration(seconds: 2));
      expect(vm.snapshot.phase, SpeechPhase.draft);
      expect(vm.snapshot.text, '明天开会');
      clock.elapse(const Duration(seconds: 5));
      expect(submissions, hasLength(1));
    });
  });
  test(
    'early hold release during startup cancels rather than recording later',
    () {
      run((clock) {
        input.startListening = false;
        start(clock);
        unawaited(vm.stop());
        clock.flushMicrotasks();
        input.emit('capture_1', SpeechEventKind.listening);
        finalResult('capture_1');
        clock.elapse(const Duration(seconds: 2));
        expect(submissions, isEmpty);
        expect(vm.snapshot.phase, SpeechPhase.cancelled);
      });
    },
  );
}
