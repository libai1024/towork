import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';

import '../../domain/attachments/local_image.dart';

class SystemImageSelector implements ImageSelector {
  @override
  Future<SelectedImage?> select() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'PNG / JPEG',
          extensions: ['png', 'jpg', 'jpeg'],
          mimeTypes: ['image/png', 'image/jpeg'],
          uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
        ),
      ],
    );
    if (file == null) return null;
    if (await file.length() > FlutterImagePreparer.maxOriginalBytes) {
      throw const AttachmentFailure(AttachmentFailureCode.tooLarge);
    }
    // Bound the actual stream too, rather than trusting only a pre-read stat.
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (builder.length + chunk.length >
          FlutterImagePreparer.maxOriginalBytes) {
        throw const AttachmentFailure(AttachmentFailureCode.tooLarge);
      }
      builder.add(chunk);
    }
    return SelectedImage(file.name, builder.takeBytes());
  }
}

/// Engine codecs validate pixels and apply encoded orientation. Only a bounded,
/// re-encoded PNG (without source metadata) is sent to the model.
class FlutterImagePreparer implements ImagePreparer {
  static const maxOriginalBytes = 10 * 1024 * 1024;
  static const maxModelBytes = 4 * 1024 * 1024;
  @override
  Future<PreparedImage> prepare(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxOriginalBytes) {
      throw const AttachmentFailure(AttachmentFailureCode.tooLarge);
    }
    final png =
        bytes.length >= 8 &&
        bytes.take(8).join(',') == '137,80,78,71,13,10,26,10';
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (!png && !jpeg) {
      throw const AttachmentFailure(AttachmentFailureCode.invalidImage);
    }
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width, height = descriptor.height;
      if (width < 1 ||
          height < 1 ||
          width > 16000 ||
          height > 16000 ||
          width * height > 40000000) {
        throw const AttachmentFailure(AttachmentFailureCode.tooLarge);
      }
      final max = width > height ? width : height;
      codec = await descriptor.instantiateCodec(
        targetWidth: max > 1600
            ? (width * 1600 / max).round().clamp(1, 1600)
            : width,
        targetHeight: max > 1600
            ? (height * 1600 / max).round().clamp(1, 1600)
            : height,
      );
      if (codec.frameCount != 1) {
        throw const AttachmentFailure(AttachmentFailureCode.invalidImage);
      }
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const AttachmentFailure(AttachmentFailureCode.invalidImage);
      }
      final normalized = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (normalized.length > maxModelBytes) {
        throw const AttachmentFailure(AttachmentFailureCode.tooLarge);
      }
      return PreparedImage(
        original: Uint8List.fromList(bytes),
        modelPng: normalized,
        mime: png ? 'image/png' : 'image/jpeg',
        width: width,
        height: height,
      );
    } on AttachmentFailure {
      rethrow;
    } catch (_) {
      throw const AttachmentFailure(AttachmentFailureCode.invalidImage);
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
