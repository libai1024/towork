import 'dart:typed_data';

/// The subset of a voice-activity detector the transcriber drives.
/// The worker isolate adapts sherpa-onnx's Silero VAD; tests use fakes.
abstract interface class VadPort {
  int get windowSize;
  void acceptWaveform(Float32List window);
  bool isDetected();
  bool isEmpty();
  Float32List front();
  void pop();
  void flush();
  void reset();
}

/// Committed sentences plus the still-changing tail of the current one.
class AsrStreamState {
  const AsrStreamState(this.committed, this.tentative);
  static const empty = AsrStreamState('', '');
  final String committed, tentative;
  String get text => joinTranscript(committed, tentative);

  @override
  bool operator ==(Object other) =>
      other is AsrStreamState &&
      other.committed == committed &&
      other.tentative == tentative;
  @override
  int get hashCode => Object.hash(committed, tentative);
}

/// VAD + non-streaming recognizer simulating streaming recognition
/// (the sherpa-onnx "simulate streaming" pattern):
///
/// * every closed sentence is decoded once and committed — from our own
///   buffer, which starts [preRollWindows] before the VAD onset, because
///   SenseVoice drops the first syllable of a tightly-cut VAD segment;
/// * while speech is open, the audio since its onset is re-decoded every
///   [tentativeStep] samples of new audio to show a live, revisable tail;
/// * [finish] flushes the VAD so the trailing sentence is committed too.
///
/// Throttling is by audio time, not wall time, so a backlog of queued audio
/// coalesces into one tentative decode instead of one per chunk.
class VadStreamingTranscriber {
  VadStreamingTranscriber(
    this._vad,
    this._recognize, {
    this.tentativeStep = 16000 * 2 ~/ 5,
    this.preRollWindows = 16,
  });

  final VadPort _vad;
  final String Function(Float32List samples) _recognize;

  /// New audio (in samples) needed before re-decoding the open sentence.
  final int tentativeStep;

  /// Windows kept before the detected onset so the first syllable survives.
  final int preRollWindows;

  final _pending = FloatBuffer();
  final _speech = FloatBuffer();
  var _committed = '';
  var _tentative = '';
  var _started = false;
  var _lastTentativeAt = 0;

  AsrStreamState get state => AsrStreamState(_committed, _tentative);

  void reset() {
    _vad.reset();
    _pending.clear();
    _speech.clear();
    _committed = '';
    _tentative = '';
    _started = false;
    _lastTentativeAt = 0;
  }

  AsrStreamState accept(Float32List samples) {
    _pending.add(samples);
    final window = _vad.windowSize;
    var offset = 0;
    while (offset + window <= _pending.length) {
      final chunk = _pending.copy(offset, window);
      offset += window;
      _vad.acceptWaveform(chunk);
      _speech.add(chunk);
      if (!_started && _vad.isDetected()) _started = true;
      if (!_started) _speech.keepLast(preRollWindows * window);
      if (_drainSegments()) {
        _speech.clear();
        _started = false;
        _lastTentativeAt = 0;
        _tentative = '';
      }
    }
    _pending.dropFirst(offset);
    if (_started && _speech.length - _lastTentativeAt >= tentativeStep) {
      _lastTentativeAt = _speech.length;
      _tentative = _recognize(_speech.copy(0, _speech.length)).trim();
    }
    return state;
  }

  /// Commits whatever speech is still open and returns the full transcript.
  String finish() {
    if (_pending.length > 0) {
      final rest = _pending.copy(0, _pending.length);
      _vad.acceptWaveform(rest);
      _speech.add(rest);
      _pending.clear();
    }
    _vad.flush();
    _drainSegments();
    _speech.clear();
    _started = false;
    _tentative = '';
    return _committed;
  }

  bool _drainSegments() {
    final segments = <Float32List>[];
    while (!_vad.isEmpty()) {
      segments.add(_vad.front());
      _vad.pop();
    }
    if (segments.isEmpty) return false;
    // One sentence closed and our buffer covers it: decode the buffer, which
    // is what the preview showed plus lead-in. Otherwise (several segments
    // at once, or a segment we never saw start) trust the VAD's cut.
    final pieces =
        segments.length == 1 &&
            _started &&
            _speech.length >= segments.single.length
        ? [_speech.copy(0, _speech.length)]
        : segments;
    for (final piece in pieces) {
      final text = _recognize(piece).trim();
      if (text.isNotEmpty) _committed = joinTranscript(_committed, text);
    }
    return true;
  }
}

/// Joins recognized pieces. CJK text concatenates directly; a space is only
/// needed between two Latin/digit boundaries ("call" + "Bob").
String joinTranscript(String head, String tail) {
  if (head.isEmpty) return tail;
  if (tail.isEmpty) return head;
  final a = head.codeUnitAt(head.length - 1);
  final b = tail.codeUnitAt(0);
  return _isWordChar(a) && _isWordChar(b) ? '$head $tail' : '$head$tail';
}

bool _isWordChar(int c) =>
    (c >= 0x30 && c <= 0x39) ||
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A);

/// Growable float32 sample buffer (no boxed doubles for minutes of audio).
class FloatBuffer {
  var _data = Float32List(4096);
  var _length = 0;
  int get length => _length;

  void add(Float32List samples) {
    final needed = _length + samples.length;
    if (needed > _data.length) {
      var size = _data.length;
      while (size < needed) {
        size *= 2;
      }
      _data = Float32List(size)..setRange(0, _length, _data);
    }
    _data.setRange(_length, needed, samples);
    _length = needed;
  }

  Float32List copy(int start, int count) => Float32List.fromList(
    Float32List.sublistView(_data, start, start + count),
  );

  void dropFirst(int count) {
    if (count <= 0) return;
    _data.setRange(0, _length - count, _data, count);
    _length -= count;
  }

  void keepLast(int count) {
    if (_length > count) dropFirst(_length - count);
  }

  void clear() => _length = 0;
}
