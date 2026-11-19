import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/attachments/local_image.dart';

/// 移动端相机/相册取图（image_picker 仅支持 Android/iOS；桌面端
/// provider 返回 null，输入栏据此隐藏拍照入口）。取回即限长，
/// 像素级校验与重编码仍由 ImagePreparer 统一完成。
class MobileImagePicker {
  MobileImagePicker([ImagePicker? picker]) : _picker = picker;
  final ImagePicker? _picker;

  Future<SelectedImage?> pick(ImageSource source) async {
    final file = await (_picker ?? ImagePicker()).pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw const AttachmentFailure(AttachmentFailureCode.tooLarge);
    }
    return SelectedImage(file.name, bytes);
  }
}

/// 文本类文件选择（file_selector，双端）。只接受明确的文本扩展名，
/// 读取时限长 512KB；内容注入对话消息，不落附件库。
class TextFileSelector {
  const TextFileSelector();

  static const maxBytes = 512 * 1024;
  static const extensions = [
    'txt',
    'md',
    'csv',
    'json',
    'log',
    'xml',
    'yaml',
    'yml',
    'ini',
    'conf',
    'html',
    'css',
    'dart',
    'ts',
    'js',
    'py',
    'sql',
    'sh',
  ];

  Future<SelectedTextFile?> select() async {
    final file = await openFile(
      acceptedTypeGroups: [XTypeGroup(label: '文本文件', extensions: extensions)],
    );
    if (file == null) return null;
    if (await file.length() > maxBytes) {
      throw const AttachmentFailure(AttachmentFailureCode.tooLarge);
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (builder.length + chunk.length > maxBytes) {
        throw const AttachmentFailure(AttachmentFailureCode.tooLarge);
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) {
      throw const AttachmentFailure(AttachmentFailureCode.invalidImage);
    }
    return SelectedTextFile(
      file.name,
      utf8.decode(bytes, allowMalformed: true),
    );
  }
}

/// 供 provider 判定平台（桌面无相机入口）。
bool get mobileMediaAvailable =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);
