import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:towork/l10n/strings.dart';

import '../../app/chat/chat_view_model.dart';
import '../../app/local_chat_runtime.dart';
import '../../app/providers.dart';
import '../../app/workspace_state.dart';
import '../../core/agent/agent_run_card.dart';
import '../../core/todo/daily_overview_panel.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/mobile_sidebar_reveal.dart';
import '../../core/widgets/work_mark.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'chat_actions.dart';
import 'widgets/chat_composer_layout.dart';
import 'widgets/chat_drawer.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_thread.dart';
import 'widgets/workspace_search.dart';

/// 对话首页（01-chat-home.md）。
/// 形态 A：空会话 = 问候 + 默认语音输入；
/// 形态 B：对话中 = 消息流 + 底部输入框，工作与资料从侧栏进入。
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _revealKey = GlobalKey<MobileSidebarRevealState>();
  final _modelAnchorKey = GlobalKey();
  bool _desktopOverviewOpen = false;
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  String? get _currentSessionId => ref.read(currentSessionIdProvider);
  set _currentSessionId(String? value) =>
      ref.read(currentSessionIdProvider.notifier).state = value;
  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text;
    final sent = await _sendPersisted(text);
    if (!mounted) return;
    if (sent && _inputController.text == text) _inputController.clear();
  }

  /// 统一发送入口：文本或带附件（附件图片用其专属 inputId 保证重试幂等）。
  Future<bool> _sendPersisted(
    String text, {
    String? inputId,
    String? attachmentId,
    bool fromVoice = false,
  }) async {
    final sent = await sendChatMessage(
      ref,
      text,
      inputId: inputId,
      attachmentId: attachmentId,
      fromVoice: fromVoice,
    );
    return sent;
  }

  void _stopGenerating() => ref.read(chatViewModelProvider.notifier).cancel();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.watch(currentSessionIdProvider);
    ref.watch(sessionListProvider);
    ref.watch(chatViewModelProvider);
    listenChatFeedback(ref, context);
    ref.listen<String?>(currentSessionIdProvider, (previous, next) {
      if (previous != next) {
        _revealKey.currentState?.close();
      }
      if (!ref.read(chatViewModelProvider).isSavingInput) {
        _inputController.clear();
      }
    });
    final session = ref
        .read(sessionListProvider.notifier)
        .sessionById(_currentSessionId);
    final desktop = MediaQuery.sizeOf(context).width >= desktopBreakpoint;
    final empty = session == null;
    final page = Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            if (ref.watch(localChatRuntimeProvider)?.readError != null)
              MaterialBanner(
                content: Text(
                  context.strings.couldntRefreshLocalChatsShowingTheLast,
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref.read(localChatRuntimeProvider)!.refresh();
                      } catch (error) {
                        if (context.mounted) {
                          AppToast.show(
                            context,
                            message: chatFailureMessage(error),
                          );
                        }
                      }
                    },
                    child: Text(context.strings.reload),
                  ),
                ],
              ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: empty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: _emptyHome(c, desktop),
                          )
                        : _conversation(c, desktop),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: _header(c, desktop, session?.title),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (desktop) {
      void closeOverview() => setState(() => _desktopOverviewOpen = false);
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): closeOverview,
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final panel = SizedBox(
              width: 400,
              child: DailyOverviewPanel(onClose: closeOverview),
            );
            if (constraints.maxWidth >= 850) {
              return Row(
                children: [
                  Expanded(child: page),
                  if (_desktopOverviewOpen) panel,
                ],
              );
            }
            return Stack(
              children: [
                Positioned.fill(child: page),
                if (_desktopOverviewOpen) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: closeOverview,
                      child: ColoredBox(
                        color: c.labelPrimary.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  Positioned(top: 0, bottom: 0, right: 0, child: panel),
                ],
              ],
            );
          },
        ),
      );
    }
    return MobileSidebarReveal(
      key: _revealKey,
      endSidebar: DailyOverviewPanel(
        onClose: () => _revealKey.currentState?.close(),
      ),
      sidebar: ChatDrawer(
        currentSessionId: _currentSessionId,
        onSessionSelected: (id) => _currentSessionId = id,
        onNewSession: () => _currentSessionId = null,
        onDismiss: () => _revealKey.currentState?.close(),
      ),
      child: page,
    );
  }

  Widget _header(AppColors c, bool desktop, String? title) => ChatHeader(
    desktop: desktop,
    onMenu: () => _revealKey.currentState?.open(),
    onSearch: () => showWorkspaceSearch(context),
    onOverview: () => desktop
        ? setState(() => _desktopOverviewOpen = !_desktopOverviewOpen)
        : _revealKey.currentState?.openEnd(),
    onNew: () {
      _stopGenerating();
      _currentSessionId = null;
    },
    onOptions: title == null ? null : () => _rename(title),
  );

  Future<void> _rename(String title) async {
    final controller = TextEditingController(text: title);
    final id = _currentSessionId;
    if (id == null) return;
    var saving = false;
    String? error;
    await AppSheet.show<void>(
      context,
      title: context.strings.renameChat,
      child: StatefulBuilder(
        builder: (sheetContext, update) {
          Future<void> save() async {
            if (saving) return;
            update(() {
              saving = true;
              error = null;
            });
            try {
              await ref
                  .read(chatViewModelProvider.notifier)
                  .renameSessionPersisted(id, controller.text);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            } catch (failure) {
              if (sheetContext.mounted) {
                update(() {
                  saving = false;
                  error = chatFailureMessage(failure);
                });
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: context.strings.chatName,
                  child: TextField(
                    key: const ValueKey('chat-session-name'),
                    controller: controller,
                    autofocus: true,
                    readOnly: saving,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: context.strings.chatName,
                      errorText: error,
                    ),
                    onSubmitted: (_) => save(),
                  ),
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: context.strings.save,
                  loading: saving,
                  expand: true,
                  onPressed: saving ? null : save,
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: sheetContext,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(context.strings.deleteThisChat),
                              content: Text(
                                context.strings.tasksCreatedInThisChatWillBe,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: Text(context.strings.cancel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: Text(context.strings.deleteLabel),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true || !sheetContext.mounted) {
                            return;
                          }
                          update(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            await ref
                                .read(chatViewModelProvider.notifier)
                                .deleteSessionPersisted(id);
                            if (mounted && _currentSessionId == id) {
                              _currentSessionId = null;
                            }
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          } catch (failure) {
                            if (sheetContext.mounted) {
                              update(() {
                                saving = false;
                                error = chatFailureMessage(failure);
                              });
                            }
                          }
                        },
                  child: Text(context.strings.deleteChat),
                ),
              ],
            ),
          );
        },
      ),
    );
    Future.delayed(const Duration(milliseconds: 400), controller.dispose);
  }

  Widget _emptyHome(AppColors c, bool desktop) {
    final copy = context.strings;
    final name = ref
        .watch(userProfileProvider)
        .displayName(copy.defaultNickname);
    final greeting = copy.hiWhatsOnYourListToday(name);
    if (!desktop) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WorkMark(size: 28),
                    const SizedBox(height: 12),
                    Text(
                      greeting,
                      key: const ValueKey('home-greeting'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(
                        color: c.labelPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _composer(true),
          ),
          const SizedBox(height: 10),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 768),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const WorkMark(size: 32),
                      const SizedBox(height: 12),
                      Text(
                        greeting,
                        key: const ValueKey('home-greeting'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display.copyWith(
                          color: c.labelPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _composer(false),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _composer(bool mobile) => ChatInputBar(
    key: ValueKey('composer-${_currentSessionId ?? 'new'}'),
    controller: _inputController,
    focusNode: _focusNode,
    isGenerating: ref.watch(chatViewModelProvider).isGenerating,
    isSavingInput: ref.watch(chatViewModelProvider).isSavingInput,
    onVoiceSubmit: (text, inputId) async {
      final sessionId = _currentSessionId;
      _inputController.text = text;
      final accepted = await sendChatMessage(
        ref,
        text,
        inputId: inputId,
        fromVoice: true,
      );
      if (mounted &&
          accepted &&
          _inputController.text == text &&
          (sessionId == null || _currentSessionId == sessionId)) {
        _inputController.clear();
      }
      return accepted;
    },
    onVoiceDraft: (text) {
      if (mounted) _inputController.text = text;
    },
    onVoiceCancel: _stopGenerating,
    onSend: _send,
    onSendMessage: (content, inputId, attachmentId) =>
        _sendPersisted(content, inputId: inputId, attachmentId: attachmentId),
    onStop: _stopGenerating,
    mobile: mobile,
    showModelSelector: true,
    modelAnchorKey: _modelAnchorKey,
  );

  Widget _conversation(AppColors c, bool desktop) {
    final generation = ref.watch(chatViewModelProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ChatComposerLayout(
          messages: (bottomPadding) => ChatThread(
            sessionId: _currentSessionId!,
            controller: _scrollController,
            horizontalPadding: desktop ? 28 : 20,
            bottomPadding: bottomPadding,
            topPadding: 76,
          ),
          composer: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (generation.error != null &&
                  ref.read(localChatRuntimeProvider) == null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(context.strings.replyIncomplete)),
                      TextButton(
                        onPressed: () =>
                            ref.read(chatViewModelProvider.notifier).retry(),
                        child: Text(context.strings.retry),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 16),
                child: _composer(!desktop),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
