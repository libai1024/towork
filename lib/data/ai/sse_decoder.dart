import 'dart:convert';

import '../../domain/ai/model_gateway.dart';

/// Incremental UTF-8 and SSE parsing, including CRLF and multiline data frames.
Stream<String> decodeSse(
  Stream<List<int>> bytes, {
  int maxResponseBytes = 4 * 1024 * 1024,
  int maxFrameCharacters = 1024 * 1024,
}) async* {
  var received = 0;
  var frameSize = 0;
  var firstLine = true;
  final data = <String>[];
  final bounded = bytes.map((chunk) {
    received += chunk.length;
    if (received > maxResponseBytes) {
      throw const ModelFailure(ModelFailureCode.budget);
    }
    return chunk;
  });
  try {
    await for (final line
        in bounded.transform(utf8.decoder).transform(const LineSplitter())) {
      // 个别服务在流首输出 UTF-8 BOM；不剥离会让首帧 data: 前缀失配被丢弃。
      var current = line;
      if (firstLine) {
        firstLine = false;
        if (current.startsWith('\uFEFF')) {
          current = current.substring(1);
        }
      }
      frameSize += current.length;
      if (frameSize > maxFrameCharacters) {
        throw const ModelFailure(ModelFailureCode.budget);
      }
      if (current.isEmpty) {
        if (data.isNotEmpty) yield data.join('\n');
        data.clear();
        frameSize = 0;
      } else if (current.startsWith('data:')) {
        var value = current.substring(5);
        if (value.startsWith(' ')) value = value.substring(1);
        data.add(value);
      }
    }
    if (data.isNotEmpty) {
      // 不规范的中转可能在 [DONE] 帧后直接关流（缺少收尾空行）。
      // 恰好只缓冲了 [DONE] 一行时按正常收尾接受，其余仍视为截断。
      if (data.length == 1 && data.single == '[DONE]') {
        yield '[DONE]';
      } else {
        throw const ModelFailure(ModelFailureCode.truncated);
      }
    }
  } on FormatException {
    throw const ModelFailure(ModelFailureCode.protocol);
  }
}
