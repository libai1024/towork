import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/platform/speech_input_selector.dart';
import 'package:towork/domain/speech/speech_input.dart';

import '../../support/free/fake_speech.dart';

void main() {
  late FakeSpeechInput native, offline;
  late SpeechInputSelector selector;
  setUp(() {
    native = FakeSpeechInput();
    offline = FakeSpeechInput();
    selector = SpeechInputSelector(native, offline, preferOffline: true);
  });
  tearDown(() async {
    await selector.dispose();
    await native.bus.close();
    await offline.bus.close();
  });
  test(
    'Android uses local model even with an available system recognizer',
    () async {
      await selector.prepare('zh-CN');
      final events = <SpeechEvent>[];
      selector.events.listen(events.add);
      await selector.start('one', locale: 'zh-CN', onDevice: false);
      expect(native.preparations, 0);
      expect(native.starts, isEmpty);
      expect(offline.starts, ['one']);
      expect(
        events.single.kind,
        SpeechEventKind.listening,
        reason: 'start emits before its Future completes',
      );
    },
  );
  test(
    'end-of-audio does not discard a later final result or cleanup',
    () async {
      final events = <SpeechEvent>[];
      selector.events.listen(events.add);
      await selector.start('one', locale: 'zh-CN', onDevice: true);
      offline.emit('one', SpeechEventKind.ended);
      offline.emit('one', SpeechEventKind.finalResult, text: '明天开会');
      expect(events.last.text, '明天开会');
      await selector.cancel('one');
      expect(offline.cancels, ['one']);
      offline.emit('one', SpeechEventKind.finalResult, text: '过期');
      expect(events.last.text, '明天开会');
    },
  );
  test('only the selected backend may emit for a capture', () async {
    final events = <SpeechEvent>[];
    selector.events.listen(events.add);
    await selector.start('one', locale: 'zh-CN', onDevice: true);
    native.emit('one', SpeechEventKind.finalResult, text: '错误来源');
    expect(events, hasLength(1));
    await selector.stop('one');
    expect(offline.stops, ['one']);
    expect(native.stops, isEmpty);
  });
}
