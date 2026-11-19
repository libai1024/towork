import 'dart:typed_data';

enum AttachmentFailureCode { invalidImage, tooLarge, missing, storage, inUse }

class AttachmentFailure implements Exception {
  const AttachmentFailure(this.code);
  final AttachmentFailureCode code;
  @override
  String toString() => 'AttachmentFailure(${code.name})';
}

class PreparedImage {
  PreparedImage({
    required this.original,
    required this.modelPng,
    required this.mime,
    required this.width,
    required this.height,
  });
  final Uint8List original, modelPng;
  final String mime;
  final int width, height;
}

class SelectedImage {
  const SelectedImage(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// 选中的文本类文件（内容已在选择时读入并限长）。
class SelectedTextFile {
  const SelectedTextFile(this.name, this.content);
  final String name;
  final String content;
}

abstract interface class ImageSelector {
  Future<SelectedImage?> select();
}

abstract interface class ImagePreparer {
  Future<PreparedImage> prepare(Uint8List bytes);
}

/// Domain metadata independent of Drift or platform file objects.
class ImageAttachment {
  const ImageAttachment({
    required this.id,
    required this.inputId,
    required this.tableId,
    required this.displayName,
    required this.mime,
    required this.originalHash,
    required this.originalSize,
    required this.modelHash,
    required this.modelSize,
    required this.width,
    required this.height,
    required this.state,
    required this.createdAt,
  });
  final String id,
      inputId,
      tableId,
      displayName,
      mime,
      originalHash,
      modelHash,
      state;
  final int originalSize, modelSize, width, height, createdAt;
}
