import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/platform/sherpa_speech_input.dart';

/// Replays PCM in 100 ms chunks at real-time pace, like `record` does.
class PacedRecorder implements AsrRecorder {
  PacedRecorder(this.pcm);
  final Uint8List pcm;
  final _chunks = StreamController<Uint8List>();
  final _drained = Completer<void>();
  Timer? _timer;
  bool started = false;
  Future<void> get drained => _drained.future;
  bool get isDrained => _drained.isCompleted;

  @override
  Future<bool> hasPermission({bool request = true}) async => true;
  @override
  Future<Stream<Uint8List>> startPcm() async {
    started = true;
    var offset = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final end = (offset + 3200).clamp(0, pcm.length);
      if (offset < end) _chunks.add(Uint8List.sublistView(pcm, offset, end));
      offset = end;
      if (offset >= pcm.length) {
        timer.cancel();
        if (!_drained.isCompleted) _drained.complete();
      }
    });
    return _chunks.stream;
  }

  @override
  Future<void> stopPcm() async {
    _timer?.cancel();
    if (!_drained.isCompleted) _drained.complete();
    if (_chunks.isClosed) return;
    // close() only completes once a listener sees "done"; a permission-probe
    // recorder is disposed without ever being listened to.
    if (started) {
      await _chunks.close();
    } else {
      unawaited(_chunks.close());
    }
  }

  @override
  Future<void> dispose() => stopPcm();
}

/// PCM16 mono 16 kHz payload of a RIFF/WAVE file.
Uint8List pcm16FromWav(Uint8List wav) {
  final view = ByteData.sublistView(wav);
  var pos = 12;
  while (pos + 8 <= wav.length) {
    final id = String.fromCharCodes(wav.sublist(pos, pos + 4));
    final size = view.getUint32(pos + 4, Endian.little);
    if (id == 'fmt ') {
      expect(view.getUint16(pos + 10, Endian.little), 1, reason: 'mono');
      expect(view.getUint32(pos + 12, Endian.little), 16000);
      expect(view.getUint16(pos + 22, Endian.little), 16);
    } else if (id == 'data') {
      return Uint8List.sublistView(wav, pos + 8, pos + 8 + size);
    }
    pos += 8 + size + (size % 2);
  }
  throw StateError('no data chunk');
}
