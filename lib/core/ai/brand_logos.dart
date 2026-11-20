import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// AI 服务商品牌（含“其他”OpenAI 兼容中转）。
enum AiBrand {
  kimi,
  kimiCode,
  deepseek,
  zhipu,
  openai,
  claude,
  gemini,
  compatible,
}

String _asset(AiBrand brand) => switch (brand) {
  // Kimi Code 复用 Kimi 官方标识。
  AiBrand.kimi || AiBrand.kimiCode => 'assets/brands/kimi.svg',
  AiBrand.deepseek => 'assets/brands/deepseek-color.svg',
  AiBrand.zhipu => 'assets/brands/zhipu.png',
  AiBrand.openai => 'assets/brands/openai.svg',
  AiBrand.claude => 'assets/brands/claude-color.svg',
  AiBrand.gemini => 'assets/brands/gemini-color.svg',
  AiBrand.compatible => '',
};

/// 品牌显示名。
String brandLabel(AiBrand brand) => switch (brand) {
  AiBrand.kimi => 'Kimi',
  AiBrand.kimiCode => 'Kimi Code',
  AiBrand.deepseek => 'DeepSeek',
  AiBrand.zhipu => strings.glm,
  AiBrand.openai => 'OpenAI',
  AiBrand.claude => 'Claude',
  AiBrand.gemini => 'Gemini',
  AiBrand.compatible => strings.otherOpenaiCompatible,
};

/// Monochrome brand artwork follows the theme foreground. Source attribution
/// is recorded in assets/brands/README.md.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.brand,
    this.size = 16,
    this.badge = false,
  });
  final AiBrand brand;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final asset = _asset(brand);
    final Widget artwork;
    if (brand == AiBrand.compatible) {
      artwork = Icon(LucideIcons.plug, size: size, color: tint);
    } else if (asset.endsWith('.png')) {
      artwork = ClipRRect(
        borderRadius: BorderRadius.circular(size * .22),
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            .2126,
            .7152,
            .0722,
            0,
            0,
            .2126,
            .7152,
            .0722,
            0,
            0,
            .2126,
            .7152,
            .0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      );
    } else {
      artwork = SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      );
    }
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Padding(
          padding: EdgeInsets.all(badge && size >= 28 ? 2 : 0),
          child: artwork,
        ),
      ),
    );
  }
}
