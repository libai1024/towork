import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/exports.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// 弹层菜单行（分享 / 更多 / 长按菜单共用）：图标 20 + body，行高 48。
class ReportMenuRow extends StatelessWidget {
  const ReportMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = destructive ? c.labelPrimary : c.labelPrimary;
    return AppPressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      semanticLabel: label,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: destructive ? c.labelPrimary : c.labelSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.body.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// 复制全文：复制 Markdown 源码（纯客户端行为）。
void copyReportMarkdown(BuildContext context, Report report) {
  Clipboard.setData(ClipboardData(text: report.contentMarkdown));
  AppToast.show(context, message: '已复制，Markdown 格式');
}

/// 导出 Markdown：报告全文写入应用支持目录/exports 下的 .md 文件。
Future<void> exportReportMarkdown(
  BuildContext context,
  WidgetRef ref,
  Report report,
) async {
  // 页面可能在写盘期间关闭：先捕获 presenter，事后仍能给出反馈。
  final present = AppToast.presenter(context);
  try {
    final directory = await ref.read(exportsDirectoryProvider.future);
    final file = File(
      '${directory.path}/report_${report.id}_${DateTime.now().millisecondsSinceEpoch}.md',
    );
    file.writeAsStringSync(report.contentMarkdown);
    present('已导出 ${file.uri.pathSegments.last}');
  } catch (_) {
    present('导出失败，请重试');
  }
}

/// 分享 Sheet：导出 Markdown｜复制全文。
void showReportShareSheet(BuildContext context, WidgetRef ref, Report report) {
  AppSheet.show<void>(
    context,
    title: '分享报告',
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReportMenuRow(
              icon: LucideIcons.fileType2,
              label: '导出 Markdown',
              onTap: () {
                Navigator.of(context).pop();
                exportReportMarkdown(context, ref, report);
              },
            ),
            ReportMenuRow(
              icon: LucideIcons.copy,
              label: '复制全文',
              onTap: () {
                Navigator.of(context).pop();
                copyReportMarkdown(context, report);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// 重新生成确认：「将用最新数据重新生成本期报告，当前内容会被覆盖。」
void confirmRegenerate(BuildContext context, WidgetRef ref, Report report) {
  final c = AppColors.of(context);
  AppSheet.show<void>(
    context,
    title: '重新生成？',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '将用最新数据重新生成本期报告，当前内容会被覆盖。',
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '取消',
                  type: AppButtonType.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: '重新生成',
                  onPressed: () {
                    ref.read(reportListProvider.notifier).regenerate(report.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// 删除确认 → 软删除 + Toast 撤销（5s）。[popAfter] 为 true 时删除后返回上一页（详情页用）。
void confirmDeleteReport(
  BuildContext context,
  WidgetRef ref,
  Report report, {
  bool popAfter = false,
}) {
  final c = AppColors.of(context);
  AppSheet.show<void>(
    context,
    title: '删掉这份报告？',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '删除报告后保留原始数据。',
            style: AppTextStyles.body.copyWith(color: c.labelSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '取消',
                  type: AppButtonType.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: '删除',
                  type: AppButtonType.destructive,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final repository = ref.read(reportListProvider.notifier);
                    repository.softDelete(report.id);
                    Navigator.of(context).pop();
                    if (popAfter) Navigator.of(context).pop();
                    AppToast.show(
                      context,
                      message: '报告已删除',
                      actionLabel: '撤销',
                      duration: const Duration(seconds: 5),
                      onAction: () {
                        if (repository.mounted) repository.restore(report.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
