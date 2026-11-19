import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/attachment_store.dart';
import '../data/platform/local_image_adapter.dart';
import '../data/platform/mobile_media_picker.dart';
import '../domain/attachments/local_image.dart';
import 'local_chat_runtime.dart';
import 'local_database_provider.dart';

final imageSelectorProvider = Provider<ImageSelector>(
  (ref) => SystemImageSelector(),
);
final imagePreparerProvider = Provider<ImagePreparer>(
  (ref) => FlutterImagePreparer(),
);

/// 移动端相机/相册取图；桌面端为 null（输入栏隐藏拍照入口）。
final mobileImagePickerProvider = Provider<MobileImagePicker?>((ref) {
  if (mobileMediaAvailable) return MobileImagePicker();
  return null;
});

/// 文本文件选择（file_selector，双端）。
final textFileSelectorProvider = Provider<TextFileSelector>(
  (ref) => const TextFileSelector(),
);

/// 对话附件能力开关：本地运行时（已连接模型工作区）就绪才可用。
/// 独立成 provider 以便 UI 测试注入。
final chatAttachmentsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(localChatRuntimeProvider) != null,
);
final attachmentStoreProvider = FutureProvider<AttachmentStore>((ref) async {
  final db = await ref.watch(localDatabaseProvider.future);
  final databases = await db.customSelect('PRAGMA database_list').get();
  final path = databases
      .singleWhere((r) => r.read<String>('name') == 'main')
      .read<String>('file');
  if (path.isEmpty) {
    throw const AttachmentFailure(AttachmentFailureCode.storage);
  }
  final store = AttachmentStore(
    db,
    Directory('${File(path).parent.path}/attachments'),
    ref.watch(imagePreparerProvider),
  );
  await store.recover();
  return store;
});
