import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/app_pressable.dart';
import '../../domain/ai/model_gateway.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_text_styles.dart';
import 'brand_logos.dart';

/// Model IDs identify their own brand. Custom or unknown IDs use a neutral mark.
AiBrand brandOfModel(String model) {
  model = model.toLowerCase();
  if (model.startsWith('deepseek')) return AiBrand.deepseek;
  if (model.startsWith('glm') ||
      model.startsWith('zhipu') ||
      model.startsWith('chatglm')) {
    return AiBrand.zhipu;
  }
  if (model.startsWith('kimi') ||
      model.startsWith('moonshot') ||
      model == 'k3' ||
      model == '快速') {
    return AiBrand.kimi;
  }
  if (model.startsWith('claude')) return AiBrand.claude;
  if (model.startsWith('gemini')) return AiBrand.gemini;
  if (model.startsWith('gpt-') || RegExp(r'^o[134](?:-|$)').hasMatch(model)) {
    return AiBrand.openai;
  }
  return AiBrand.compatible;
}

AiBrand brandOfProduct(ProviderKind product) => switch (product) {
  ProviderKind.moonshot || ProviderKind.kimiCode => AiBrand.kimi,
  ProviderKind.deepseek => AiBrand.deepseek,
  ProviderKind.zhipu || ProviderKind.zhipuCoding => AiBrand.zhipu,
  ProviderKind.custom => AiBrand.compatible,
};

class ProviderLogo extends StatelessWidget {
  const ProviderLogo(this.product, {super.key, this.size = 16});
  final ProviderKind product;
  final double size;

  @override
  Widget build(BuildContext context) =>
      BrandLogo(brand: brandOfProduct(product), size: size);
}

/// 各服务商的模型清单，出自服务商目录（连接页建议与对话页模型切换共用）。
List<String> modelsForProduct(ProviderKind product) => [
  for (final preset in ProviderCatalog.of(product).models) preset.id,
];

/// 服务商显示名（对话页模型切换头部与额度页「模型服务」行共用）。
String productLabel(ProviderKind product) =>
    ProviderCatalog.of(product).shortLabel;

String shortModelLabel(String model) => ProviderCatalog.modelLabel(model);

/// AI 生成标记：品牌 logo + 短名，用于区分不同模型产生的记录。
/// [model] 为空（历史数据/演示）时回退通用 AI 图标。
class ModelSourceBadge extends StatelessWidget {
  const ModelSourceBadge({super.key, this.model, this.product, this.onTap});
  final ProviderKind? product;
  final String? model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final known = model != null && model!.isNotEmpty;
    final brand = product != null
        ? brandOfProduct(product!)
        : known
        ? brandOfModel(model!)
        : null;
    final label = known ? shortModelLabel(model!) : 'AI';
    final content = Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(color: c.fill1, borderRadius: AppRadii.brFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (brand != null)
            BrandLogo(brand: brand, size: 12)
          else
            Icon(LucideIcons.sparkles, size: 12, color: c.labelSecondary),
          const SizedBox(width: 4),
          // 窄列表里徽章可被压缩：标签省略而不撑破行。
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: c.labelSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Tooltip(
      message: known ? '查看来源会话（由 $label 生成）' : '查看来源会话',
      child: AppPressable(
        onTap: onTap,
        semanticLabel: '查看待办来源会话',
        child: SizedBox(width: 44, height: 44, child: Center(child: content)),
      ),
    );
  }
}

/// 图标 + 模型名（模型切换按钮/列表行用），不含底色。
class ModelIdentityRow extends StatelessWidget {
  const ModelIdentityRow({super.key, required this.model, this.dimmed = false});
  final String model;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = dimmed ? c.labelTertiary : c.labelPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(brand: brandOfModel(model), size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            shortModelLabel(model),
            style: AppTextStyles.menuLabel.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
