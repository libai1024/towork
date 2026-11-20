import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/local_chat_runtime.dart';
import '../../app/workspace_state.dart';
import '../../core/widgets/app_toast.dart';
import '../../app/chat/chat_view_model.dart';
import '../../core/agent/agent_run_card.dart';

/// 按当前选中的模型和开关发送一条消息。对话页与快捷面板共用，保证
/// 文字、语音、带附件三种发送走同一套参数。
Future<bool> sendChatMessage(
  WidgetRef ref,
  String text, {
  String? inputId,
  String? attachmentId,
  String? replyToInputId,
  bool fromVoice = false,
}) => ref
    .read(chatViewModelProvider.notifier)
    .sendPersisted(
      text,
      model:
          '${ref.read(chatModelProvider)}'
          '${ref.read(chatAdvancedProvider) ? strings.advanced : ''}',
      agentEnabled: ref.read(chatAgentEnabledProvider),
      inputId: inputId,
      attachmentId: attachmentId,
      replyToInputId: replyToInputId,
      fromVoice: fromVoice,
    );

/// 把生成状态变成用户能感知的反馈：失败和提示弹轻提示，顺利完成时
/// 轻震一下。必须在 `build` 里调用。
void listenChatFeedback(WidgetRef ref, BuildContext context) {
  ref.listen(chatViewModelProvider, (previous, next) {
    if (next.error != null && previous?.error != next.error) {
      AppToast.show(
        context,
        message: ref.read(localChatRuntimeProvider) == null
            ? context.strings.couldntReplyTryAgain
            : chatFailureMessage(next.error),
      );
    }
    if (next.notice != null && previous?.notice != next.notice) {
      AppToast.show(context, message: next.notice!);
    }
    if (previous?.isGenerating == true &&
        !next.isGenerating &&
        next.error == null) {
      HapticFeedback.mediumImpact();
    }
  });
}
