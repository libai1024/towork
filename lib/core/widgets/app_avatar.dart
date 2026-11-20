import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_pressable.dart';

/// 头像（规范 §3.1 形态 A 顶栏）：r-full。
/// 未设置头像图时：fill2 底 + 昵称首字 footnote labelSecondary。
/// 触控热区固定 44×44。
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.nickname,
    this.size = 32,
    this.imageUrl,
    this.onTap,
    this.semanticLabel,
  });

  final String nickname;
  final double size;
  final String? imageUrl;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final initial = nickname.isEmpty ? '?' : nickname.characters.first;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.fill2,
        shape: BoxShape.circle,
        image: imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              ),
      ),
      alignment: Alignment.center,
      child: imageUrl == null
          ? Text(
              initial,
              style: AppTextStyles.footnote.copyWith(color: c.labelSecondary),
            )
          : null,
    );

    if (onTap == null) return avatar;
    return AppPressable(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      semanticLabel: semanticLabel ?? context.strings.avatar,
      child: Center(child: avatar),
    );
  }
}
