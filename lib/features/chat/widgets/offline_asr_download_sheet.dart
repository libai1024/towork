import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/speech_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 离线语音识别模型下载弹层：说明来源与体积，进度按字节展示，可取消。
/// 下载完成回调 [onReady]，由调用方重新发起语音输入。
Future<void> showOfflineAsrDownloadSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onReady,
}) => AppSheet.show<void>(
  context,
  title: '离线语音识别',
  child: _OfflineAsrDownloadSheet(onReady: onReady),
);

class _OfflineAsrDownloadSheet extends ConsumerStatefulWidget {
  const _OfflineAsrDownloadSheet({this.onReady});
  final VoidCallback? onReady;

  @override
  ConsumerState<_OfflineAsrDownloadSheet> createState() =>
      _OfflineAsrDownloadSheetState();
}

class _OfflineAsrDownloadSheetState
    extends ConsumerState<_OfflineAsrDownloadSheet> {
  @override
  void initState() {
    super.initState();
    // 打开即刷新磁盘状态并触发随包资产安装（已就绪时为空操作）；
    // 冷启动已在后台安装，多数情况下这里直接就绪。
    Future.microtask(() {
      ref.read(offlineAsrModelProvider.notifier).refresh();
      ref.read(offlineAsrModelProvider.notifier).install();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = ref.watch(offlineAsrModelProvider);
    final total = offlineAsrModelTotalBytes;
    final mb = (state.downloadedBytes / 1024 / 1024).toStringAsFixed(1);
    final totalMb = (total / 1024 / 1024).toStringAsFixed(0);

    if (state.ready) {
      // 就绪即后台预热模型；用户读提示的一两秒正好完成装载。
      Future.microtask(() => ref.read(warmOfflineSpeechProvider)());
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.circleCheck, size: 22, color: c.brand),
            const SizedBox(height: 10),
            Text(
              '离线模型已就绪',
              style: AppTextStyles.body.copyWith(color: c.labelPrimary),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: '开始语音输入',
              expand: true,
              onPressed: () {
                Navigator.of(context).pop();
                widget.onReady?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '使用内置模型在本机转写，无需联网。',
            style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: 10),
          if (state.installing) ...[
            LinearProgressIndicator(
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: c.fill2,
              color: c.brand,
            ),
            const SizedBox(height: 8),
            Text(
              '正在安装内置离线模型…',
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: '联网下载（约 $totalMb MB）',
              type: AppButtonType.secondary,
              expand: true,
              onPressed: () {
                ref.read(offlineAsrModelProvider.notifier).cancelInstall();
                ref.read(offlineAsrModelProvider.notifier).download();
              },
            ),
          ] else if (state.downloading) ...[
            LinearProgressIndicator(
              value: state.downloadedBytes / total,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: c.fill2,
              color: c.brand,
            ),
            const SizedBox(height: 8),
            Text(
              '$mb / $totalMb MB',
              style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: '取消下载',
              type: AppButtonType.secondary,
              expand: true,
              onPressed: () =>
                  ref.read(offlineAsrModelProvider.notifier).cancelDownload(),
            ),
          ] else if (state.error != null) ...[
            Text(
              state.error!,
              style: AppTextStyles.footnote.copyWith(color: c.red),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: '重试下载',
                    onPressed: () =>
                        ref.read(offlineAsrModelProvider.notifier).download(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: '重新安装内置模型',
                    type: AppButtonType.secondary,
                    onPressed: () =>
                        ref.read(offlineAsrModelProvider.notifier).install(),
                  ),
                ),
              ],
            ),
          ] else ...[
            AppButton(
              label: '安装内置离线模型',
              icon: LucideIcons.box,
              expand: true,
              onPressed: () =>
                  ref.read(offlineAsrModelProvider.notifier).install(),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: '改为联网下载（约 $totalMb MB）',
              type: AppButtonType.secondary,
              expand: true,
              onPressed: () =>
                  ref.read(offlineAsrModelProvider.notifier).download(),
            ),
          ],
          if (!state.downloading &&
              state.downloadedBytes > 0 &&
              state.error == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '已下载 $mb / $totalMb MB',
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
