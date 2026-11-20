import 'package:towork/l10n/strings.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/assist_provider.dart';
import '../app/navigation_requests.dart';
import '../app/providers.dart';
import '../app/workspace_state.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_chip.dart';
import '../core/widgets/work_mark.dart';
import '../domain/assist/quick_assist.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../features/chat/chat_actions.dart';
import '../app/chat/chat_view_model.dart';
import '../features/chat/widgets/chat_input_bar.dart';
import '../features/chat/widgets/chat_model_button.dart';
import '../features/chat/widgets/chat_thread.dart';
import '../features/quick_assist/quick_assist_sheet.dart';

/// 快捷面板：在别的应用上方半屏展开的一段对话。
///
/// 每次唤起都是一段新对话，和主应用共用同一份本地数据。分享或划词
/// 带进来的文字只预填进输入框。离开面板不会打断正在生成的回复：面板
/// 收到后台等它收完，待办照常落库。
class QuickAssistPanel extends ConsumerStatefulWidget {
  const QuickAssistPanel({super.key});

  /// 面板收到后台后最多再等这么久；之后停止生成并退出。
  static const backgroundLimit = Duration(minutes: 3);

  @override
  ConsumerState<QuickAssistPanel> createState() => _QuickAssistPanelState();
}

class _QuickAssistPanelState extends ConsumerState<QuickAssistPanel> {
  final _sheet = GlobalKey<QuickAssistSheetState>();
  final _modelAnchor = GlobalKey();
  final _voiceBounds = GlobalKey();
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _voice = _Pulse();
  late final AssistHost _host;
  late final AppNavigationRequests _requests;
  StreamSubscription<AssistLaunch>? _relaunches;

  /// 分享或划词带进来的原文，决定空白页给出哪些建议。
  String _shared = '';

  /// 面板正在离场，或已经收到后台。
  bool _leaving = false;

  /// 每次被重新唤起加一，作废之前排队的「收完就关」。
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    _host = ref.read(assistHostProvider);
    _requests = ref.read(appNavigationRequestsProvider);
    // 面板里没有路由器。要去设置页时把去向带回主应用。
    _requests.attach(_navigate);
    _input.addListener(_inputChanged);
    _relaunches = _host.relaunches.listen(_relaunch);
    unawaited(_host.launch().then(_apply));
  }

  @override
  void dispose() {
    _requests.detach(_navigate);
    unawaited(_relaunches?.cancel());
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    _voice.dispose();
    super.dispose();
  }

  void _inputChanged() {
    if (_shared.isNotEmpty && _input.text.isEmpty) {
      setState(() => _shared = '');
    }
  }

  void _apply(AssistLaunch launch) {
    if (!mounted) return;
    if (launch.text.isNotEmpty) {
      setState(() => _shared = launch.text);
      _input.value = TextEditingValue(
        text: launch.text,
        selection: TextSelection.collapsed(offset: launch.text.length),
      );
    } else if (launch.voice) {
      // 输入条要先挂上监听。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _voice.fire();
      });
    } else if (ref.read(defaultInputModeProvider) == ChatInputMode.keyboard) {
      _focus.requestFocus();
    }
  }

  void _relaunch(AssistLaunch launch) {
    if (!mounted) return;
    if (_leaving) {
      // 面板收在后台等回复时又被唤起：重新亮出来，接着这段对话。
      _epoch++;
      _leaving = false;
    } else if (!ref.read(chatViewModelProvider).isGenerating) {
      _newConversation();
    }
    _sheet.currentState?.show();
    _apply(launch);
  }

  void _navigate(String location) => unawaited(_openApp(location: location));

  Future<bool> _sendMessage(
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

  Future<void> _send() async {
    final text = _input.text;
    final sent = await _sendMessage(text);
    if (mounted && sent && _input.text == text) _input.clear();
  }

  /// 建议项：直接发出一句话。针对带入文字的建议已经把原文带上了，
  /// 输入框里那份随之清掉。
  Future<void> _ask(String text) async {
    final shared = _shared;
    final sent = await _sendMessage(text);
    if (mounted && sent && shared.isNotEmpty && _input.text == shared) {
      _input.clear();
    }
  }

  void _prefill(String text) {
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _focus.requestFocus();
  }

  void _stop() => ref.read(chatViewModelProvider.notifier).cancel();

  void _newConversation() {
    _stop();
    _input.clear();
    setState(() => _shared = '');
    ref.read(currentSessionIdProvider.notifier).state = null;
  }

  /// 等当前回复收完。超时返回 false。
  Future<bool> _idle(Duration limit) async {
    if (!ref.read(chatViewModelProvider).isGenerating) return true;
    try {
      // 对话状态被整个换掉时流会直接结束，那也就没有什么可等的了。
      await ref
          .read(chatViewModelProvider.notifier)
          .stream
          .firstWhere(
            (state) => !state.isGenerating,
            orElse: () => const ChatGenerationState(),
          )
          .timeout(limit);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  /// 面板已经收到后台。引擎活着这次回复才收得完，所以等它结束再退出；
  /// 等太久就停掉，不让一个看不见的面板一直占着内存。
  Future<void> _closeWhenIdle(int epoch) async {
    if (!await _idle(QuickAssistPanel.backgroundLimit)) {
      if (!mounted || epoch != _epoch) return;
      _stop();
      await _idle(const Duration(seconds: 3));
    }
    if (!mounted || epoch != _epoch) return;
    await _host.close();
  }

  Future<void> _close() async {
    if (_leaving) return;
    _leaving = true;
    final epoch = _epoch;
    _focus.unfocus();
    await _sheet.currentState?.dismiss();
    if (!mounted || epoch != _epoch) return;
    if (ref.read(chatViewModelProvider).isGenerating) {
      await _host.hide(context.strings.generatingInBackground);
      await _closeWhenIdle(epoch);
    } else {
      await _host.close();
    }
  }

  Future<void> _openApp({String? location}) async {
    if (_leaving) return;
    _leaving = true;
    final epoch = _epoch;
    _focus.unfocus();
    final handoff = AssistHandoff(
      sessionId: ref.read(currentSessionIdProvider),
      location: location,
    );
    await _sheet.currentState?.dismiss();
    if (!mounted || epoch != _epoch) return;
    final generating = ref.read(chatViewModelProvider).isGenerating;
    await _host.openApp(handoff, keepPanel: generating);
    if (generating) await _closeWhenIdle(epoch);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sessionId = ref.watch(currentSessionIdProvider);
    ref.watch(sessionListProvider);
    final generation = ref.watch(chatViewModelProvider);
    listenChatFeedback(ref, context);
    final session = ref
        .read(sessionListProvider.notifier)
        .sessionById(sessionId);
    return Material(
      type: MaterialType.transparency,
      child: QuickAssistSheet(
        key: _sheet,
        contentKey: _voiceBounds,
        onDismiss: _close,
        header: _header(c, hasSession: session != null),
        body: Column(
          children: [
            Expanded(
              child: session == null
                  ? _empty(c)
                  : ChatThread(
                      sessionId: session.id,
                      controller: _scroll,
                      horizontalPadding: 16,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: ChatInputBar(
                voiceBounds: _voiceBounds,
                controller: _input,
                focusNode: _focus,
                isGenerating: generation.isGenerating,
                isSavingInput: generation.isSavingInput,
                mobile: true,
                voiceSignal: _voice,
                onSend: _send,
                onSendMessage: (content, inputId, attachmentId) => _sendMessage(
                  content,
                  inputId: inputId,
                  attachmentId: attachmentId,
                ),
                onStop: _stop,
                onVoiceSubmit: (text, inputId) async {
                  _input.text = text;
                  final accepted = await _sendMessage(
                    text,
                    inputId: inputId,
                    fromVoice: true,
                  );
                  if (mounted && accepted && _input.text == text) {
                    _input.clear();
                  }
                  return accepted;
                },
                onVoiceDraft: (text) {
                  if (mounted) _input.text = text;
                },
                onVoiceCancel: _stop,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppColors c, {required bool hasSession}) {
    Widget action(
      IconData icon,
      String label,
      VoidCallback onTap, {
      Key? key,
    }) => IconButton(
      key: key,
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: c.labelSecondary),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ChatModelButton(anchorKey: _modelAnchor),
            ),
          ),
          if (hasSession)
            action(
              LucideIcons.messageCirclePlus,
              context.strings.newChatHeader,
              _newConversation,
              key: const ValueKey('quick-assist-new'),
            ),
          action(
            LucideIcons.externalLink,
            context.strings.openInTowork,
            _openApp,
            key: const ValueKey('quick-assist-open-app'),
          ),
          action(
            LucideIcons.x,
            context.strings.close,
            _close,
            key: const ValueKey('quick-assist-close'),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppColors c) {
    final shared = _shared;
    final suggestions = shared.isEmpty
        ? <(String, VoidCallback)>[
            (
              context.strings.whatsLeftToday,
              () => _ask(context.strings.whatElseDoINeedToDo),
            ),
            (
              context.strings.addATask,
              () => _prefill(context.strings.helpMeAddATask),
            ),
            (
              context.strings.whatDidIDoThisWeek,
              () => _ask(context.strings.summarizeWhatICompletedThisWeek),
            ),
          ]
        : <(String, VoidCallback)>[
            (
              context.strings.saveAsTask,
              () => _ask(context.strings.turnThisIntoATask(shared)),
            ),
            (
              context.strings.summarize,
              () => _ask(context.strings.summarizeTheseKeyPoints(shared)),
            ),
          ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WorkMark(size: 26),
            const SizedBox(height: 8),
            Text(
              shared.isEmpty
                  ? context.strings.quickAsk
                  : context.strings.workWithThisText,
              key: const ValueKey('quick-assist-greeting'),
              textAlign: TextAlign.center,
              style: AppTextStyles.displaySmall.copyWith(color: c.labelPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final (label, onTap) in suggestions)
                  AppChip(
                    key: ValueKey('quick-assist-suggestion-$label'),
                    label: label,
                    height: 36,
                    onTap: onTap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 只负责「响一下」的通知器：让输入条开始一次听写。
class _Pulse extends ChangeNotifier {
  void fire() => notifyListeners();
}

/// 工作区还没就绪时面板的样子。
///
/// 加载时保持透明，面板准备好再从底部出现。
/// 打不开时给出重试和关闭。两种情况点空白处都能退出。
class QuickAssistStartup extends ConsumerWidget {
  const QuickAssistStartup({super.key, required this.retry});

  /// 为空表示还在加载。
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final close = ref.read(assistHostProvider).close;
    final retry = this.retry;
    if (retry == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: close,
        child: const SizedBox.expand(),
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: QuickAssistSheet(
        onDismiss: close,
        header: const SizedBox(height: 12),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.strings.couldntOpenTheWorkspaceYourDataIs,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                ),
                const SizedBox(height: 10),
                AppButton(label: context.strings.reopen, onPressed: retry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
