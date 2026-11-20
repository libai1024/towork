import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_empty_state.dart';

/// 占位页骨架：带返回的顶栏 + 居中空状态。
/// 后续各页面由对应实现替换，路由路径与文件名约定不变。
class UnderConstructionPage extends StatelessWidget {
  const UnderConstructionPage({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: AppTextStyles.subhead.copyWith(color: c.labelPrimary),
        ),
      ),
      body: AppEmptyState(
        icon: LucideIcons.hammer,
        title: context.strings.inDevelopment,
        message: subtitle,
      ),
    );
  }
}
