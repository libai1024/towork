import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/platform/vad_streaming_transcriber.dart';

/// Scripted VAD: a window whose first sample is >= 0.5 counts as speech; a
/// segment closes after [silenceWindows] quiet windows, like Silero's
/// min-silence rule. [flush] closes any open segment.
class _FakeVad implements VadPort {
  static const silenceWindows = 2;
  final _ready = <Float32List>[];
  final _open = <double>[];
  int _quiet = 0;
  bool _detected = false;
  int resets = 0;
  @override
  int get windowSize => 4;
  @override
  void acceptWaveform(Float32List window) {
    final speech = window.first >= 0.5;
    if (speech) {
      _detected = true;
      _quiet = 0;
      _open.addAll(window);
    } else if (_detected) {
      _quiet++;
      if (_quiet >= silenceWindows) _close();
    }
  }

  void _close() {
    if (_open.isNotEmpty) _ready.add(Float32List.fromList(_open));
    _open.clear();
    _detected = false;
    _quiet = 0;
  }

  @override
  bool isDetected() => _detected;
  @override
  bool isEmpty() => _ready.isEmpty;
  @override
  Float32List front() => _ready.first;
  @override
  void pop() => _ready.removeAt(0);
  @override
  void flush() => _close();
  @override
  void reset() {
    resets++;
    _ready.clear();
    _open.clear();
    _detected = false;
  }
}

Float32List _speech(int windows) =>
    Float32List(windows * 4)..fillRange(0, windows * 4, 0.9);
Float32List _silence(int windows) => Float32List(windows * 4);

void main() {
  late _FakeVad vad;
  late List<int> decodedLengths;
  late List<String> scripted;
  late VadStreamingTranscriber transcriber;

  setUp(() {
    vad = _FakeVad();
    decodedLengths = [];
    scripted = [];
    transcriber = VadStreamingTranscriber(
      vad,
      (samples) {
        decodedLengths.add(samples.length);
        return scripted.isEmpty ? '' : scripted.removeAt(0);
      },
      tentativeStep: 8,
      preRollWindows: 1,
    );
  });

  test('silence alone never invokes the recognizer', () {
    final state = transcriber.accept(_silence(20));
    expect(state, AsrStreamState.empty);
    expect(decodedLengths, isEmpty);
    expect(transcriber.finish(), '');
  });

  test('open speech shows a tentative tail, closed speech commits', () {
    scripted.add('明天');
    var state = transcriber.accept(_speech(2));
    expect(state.tentative, '明天');
    expect(state.committed, '');

    scripted.add('明天开会，');
    state = transcriber.accept(
      Float32List.fromList([..._speech(1), ..._silence(2)]),
    );
    expect(state.committed, '明天开会，');
    expect(state.tentative, '', reason: '断句后清空待定尾巴');
    expect(state.text, '明天开会，');
  });

  test('tentative decode is throttled by audio time, not by chunk count', () {
    scripted.addAll(['a', 'b', 'c']);
    for (var i = 0; i < 4; i++) {
      transcriber.accept(Float32List.fromList(_speech(1)));
    }
    // 16 speech samples with an 8-sample step -> two tentative decodes.
    expect(decodedLengths, hasLength(2));
  });

  test('partial windows carry over between chunks', () {
    scripted.add('x');
    transcriber.accept(Float32List.fromList(_speech(1).sublist(0, 3)));
    expect(decodedLengths, isEmpty);
    transcriber.accept(Float32List.fromList([0.9, ..._speech(1)]));
    expect(decodedLengths.single, 8, reason: '3+1 样本拼成完整窗口');
  });

  test('finish flushes the trailing sentence and joins with commits', () {
    // Segment closes inside the chunk: one segment decode, no tentative.
    scripted.add('第一句。');
    transcriber.accept(Float32List.fromList([..._speech(2), ..._silence(2)]));
    // Committed from our buffer: 2 speech + 2 trailing-silence windows.
    expect(decodedLengths, [16]);
    // Open speech: one tentative decode, then the flushed segment on finish.
    scripted.addAll(['second?', 'second']);
    expect(transcriber.accept(_speech(2)).text, '第一句。second?');
    expect(transcriber.finish(), '第一句。second');
    expect(transcriber.state.tentative, '');
  });

  test('committed sentence keeps lead-in audio before the VAD onset', () {
    final lengths = <int>[];
    final t = VadStreamingTranscriber(
      vad,
      (samples) {
        lengths.add(samples.length);
        return '重点';
      },
      tentativeStep: 1 << 20,
      preRollWindows: 2,
    );
    t.accept(
      Float32List.fromList([..._silence(5), ..._speech(2), ..._silence(2)]),
    );
    // 2 pre-roll windows + 2 speech + 2 silence; the fake VAD's own segment
    // is only the 8 speech samples.
    expect(lengths, [24]);
    expect(t.state.committed, '重点');
  });

  test('reset drops prior session state', () {
    scripted.add('旧的');
    transcriber.accept(Float32List.fromList([..._speech(2), ..._silence(2)]));
    transcriber.reset();
    expect(transcriber.state, AsrStreamState.empty);
    expect(vad.resets, 1);
  });

  test('joinTranscript spaces only between Latin words', () {
    expect(joinTranscript('call', 'Bob'), 'call Bob');
    expect(joinTranscript('明天', '开会'), '明天开会');
    expect(joinTranscript('Hi.', 'OK'), 'Hi.OK');
    expect(joinTranscript('会议', 'at 3'), '会议at 3');
    expect(joinTranscript('', 'x'), 'x');
  });

  test('FloatBuffer grows, drops and keeps the tail', () {
    final b = FloatBuffer();
    b.add(Float32List.fromList(List.generate(5000, (i) => i.toDouble())));
    expect(b.length, 5000);
    b.dropFirst(4990);
    expect(b.copy(0, b.length).first, 4990);
    b.keepLast(3);
    expect(b.copy(0, 3), [4997, 4998, 4999]);
  });
}
