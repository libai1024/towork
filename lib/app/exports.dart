import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// 导出文件统一落盘目录（应用支持目录下的 exports/）。
/// 设置页备份、数据表 CSV、报告 Markdown 共用；测试以临时目录覆写。
final exportsDirectoryProvider = FutureProvider<Directory>((ref) async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/exports');
  directory.createSync(recursive: true);
  return directory;
});
