import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/model_settings_provider.dart';
import '../../../app/local_chat_runtime.dart';
import '../../../app/workspace_state.dart';
import '../../../core/ai/brand_logos.dart';
import '../../../core/ai/model_identity.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'chat_model_picker.dart';

/// The model picker follows the composer across window and keyboard changes.
class ChatModelButton extends ConsumerStatefulWidget {
  const ChatModelButton({
    super.key,
    this.enabled = true,
    this.mobile = false,
    this.anchorKey,
  });
  final bool enabled;
  final bool mobile;
  final GlobalKey? anchorKey;

  @override
  ConsumerState<ChatModelButton> createState() => _ChatModelButtonState();
}

class _ChatModelButtonState extends ConsumerState<ChatModelButton> {
  final _anchor = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final model = ref.watch(chatModelProvider);
    final account = ref.watch(liveModelAccountsProvider)?.active;
    final live = ref.watch(localChatRuntimeProvider) != null;
    final label = account != null
        ? account.descriptor.preset(account.profile.model)?.label ??
              account.profile.model
        : live
        ? '连接模型'
        : model;
    return Tooltip(
      message: '选择模型',
      child: AppPressable(
        key: widget.anchorKey ?? _anchor,
        minSize: widget.mobile ? 48 : 44,
        semanticLabel: '选择模型，$label',
        onTap: widget.enabled
            ? () => showChatModels(
                context,
                ref,
                anchorKey: widget.anchorKey ?? _anchor,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (account != null || !live) ...[
                  BrandLogo(
                    brand: account == null
                        ? brandOfModel(model)
                        : brandOfProduct(account.profile.product),
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.modelLabel.copyWith(
                      color: colors.labelSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
