import 'package:towork/l10n/strings.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../view_models/speech_capture_controller.dart';
import '../../../app/attachment_provider.dart';
import '../../../app/speech_provider.dart';
import '../../../app/update/restart_readiness.dart';
import 'chat_speech_messages.dart';
export 'chat_speech_messages.dart' show speechProblemMessage;

import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../../app/local_chat_runtime.dart';
import '../../../domain/attachments/local_image.dart';

import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_toast.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/workspace_state.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_inline_input.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'chat_model_button.dart';
import 'chat_voice_feedback.dart';
import 'chat_voice_control.dart';
import 'chat_voice_overlay.dart';

export 'chat_model_picker.dart' show showChatModels;

part 'chat_attachment_chip.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isGenerating,
    required this.onSend,
    required this.onStop,
    this.mobile = false,
    this.isSavingInput = false,
    this.onVoiceSubmit,
    this.onVoiceDraft,
    this.onVoiceCancel,
    this.onSendMessage,
    this.voiceSignal,
    this.showModelSelector = false,
    this.modelAnchorKey,
    this.voiceBounds,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isGenerating;
  final VoidCallback onSend, onStop;
  final bool mobile;
  final bool isSavingInput;
  final Future<bool> Function(String text, String inputId)? onVoiceSubmit;
  final ValueChanged<String>? onVoiceDraft;
  final VoidCallback? onVoiceCancel;

  /// 发送（可带附件）。附件图片以 [LocalChatRuntime] 的持久附件为准：
  /// [inputId]/[attachmentId] 来自所选图片行；文本文件已内联进 [content]。
  /// 返回是否成功；成功后组件负责清空输入框与待发附件。
  final Future<bool> Function(
    String content,
    String? inputId,
    String? attachmentId,
  )?
  onSendMessage;

  /// 每次通知都直接开始一次听写。快捷面板被
  /// 语音指令键唤起时用它直接进入听写。
  final Listenable? voiceSignal;
  final bool showModelSelector;
  final GlobalKey? modelAnchorKey, voiceBounds;
  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

/// Single glass composer; voice capture stays inline with the normal input.
class _ChatInputBarState extends ConsumerState<ChatInputBar>
    with WidgetsBindingObserver {
  SpeechCaptureController? _capture;
  void Function()? _removeListener;
  bool _holding = false;
  VoiceZone _zone = VoiceZone.none;
  final _voiceTargets = GlobalKey();
  final _voiceFeedback = VoiceOverlayController();
  final _voiceGesture = GlobalKey();
  bool _editingVoice = false;
  bool _disposing = false;
  ChatInputMode? _mode;

  /// 待发附件：图片（持久附件行 + 预览字节）或文本文件（内容内联）。
  ImageAttachment? _pendingImage;
  Uint8List? _pendingImagePreview;
  SelectedTextFile? _pendingText;
  bool _picking = false;
  late Set<bool Function()> _restartGuards;
  bool _canRestart() =>
      widget.controller.text.isEmpty &&
      !_hasAttachment &&
      !_picking &&
      _capture == null &&
      !widget.isSavingInput &&
      !widget.isGenerating;

  @override
  void initState() {
    super.initState();
    _restartGuards = ref.read(updateRestartGuardsProvider)..add(_canRestart);
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
    widget.voiceSignal?.addListener(_startVoice);
    // Copy the bundled speech model to disk after first paint so the first
    // tap on the mic doesn't wait for it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(prefetchOfflineSpeechProvider)();
    });
  }

  @override
  void dispose() {
    _disposing = true;
    _restartGuards.remove(_canRestart);
    WidgetsBinding.instance.removeObserver(this);
    _removeListener?.call();
    _capture?.dispose();
    _voiceFeedback.dispose();
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    widget.voiceSignal?.removeListener(_startVoice);
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceSignal != widget.voiceSignal) {
      oldWidget.voiceSignal?.removeListener(_startVoice);
      widget.voiceSignal?.addListener(_startVoice);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final capture = _capture;
    if (capture == null || state == AppLifecycleState.resumed) return;
    // The system permission prompt temporarily makes the app inactive.
    if (state == AppLifecycleState.inactive &&
        capture.snapshot.phase == SpeechPhase.requesting) {
      return;
    }
    _useKeyboard();
  }

  void _changed() {
    if (!mounted || _disposing) return;
    setState(() {
      if (_capture == null &&
          (widget.controller.text.isNotEmpty || widget.focusNode.hasFocus)) {
        _mode = ChatInputMode.keyboard;
      }
    });
  }

  void _submit() {
    if (widget.isGenerating || widget.isSavingInput || _capture != null) {
      return;
    }
    if (_pendingImage == null &&
        _pendingText == null &&
        widget.controller.text.trim().isEmpty) {
      return;
    }
    if (widget.onSendMessage == null && _hasAttachment) return;
    unawaited(_submitWithAttachment());
  }

  bool get _hasAttachment => _pendingImage != null || _pendingText != null;

  /// 附件消息内容：图片沿用「图片「名」：指示」约定；文本文件把限长后
  /// 的内容内联进消息（prepare 上限 20000 字符，留足余量）。
  Future<void> _submitWithAttachment() async {
    final image = _pendingImage;
    final textFile = _pendingText;
    final prompt = widget.controller.text.trim();
    final String content;
    if (image != null) {
      content =
          '${context.strings.image(image.displayName)}'
          '${prompt.isEmpty ? context.strings.takeALookAtThisImage : prompt}';
    } else if (textFile != null) {
      const cap = 18000;
      final body = textFile.content.length > cap
          ? context.strings.contentTruncated(textFile.content.substring(0, cap))
          : textFile.content;
      content = prompt.isEmpty
          ? context.strings.contentsOf(textFile.name, body)
          : context.strings.contentsOfSubmitwithattachment(
              prompt,
              textFile.name,
              body,
            );
    } else {
      content = prompt;
    }
    final handler = widget.onSendMessage;
    bool sent;
    if (handler != null) {
      sent = await handler(content, image?.inputId, image?.id);
    } else {
      widget.onSend();
      sent = true;
    }
    if (!mounted || !sent) return;
    _discardAttachment(keepImage: true);
    setState(() {
      _pendingImage = null;
      _pendingImagePreview = null;
      _pendingText = null;
    });
    if (widget.controller.text.trim() == prompt && prompt.isNotEmpty) {
      widget.controller.clear();
    }
  }

  /// 移除待发附件；未发送的图片附件同步清理暂存文件（静默失败可重试）。
  void _discardAttachment({bool keepImage = false}) {
    final row = _pendingImage;
    if (row == null || keepImage) return;
    unawaited(
      ref
          .read(attachmentStoreProvider.future)
          .then((store) {
            return store.removeDraft(row.id);
          })
          .catchError((Object _) {}),
    );
  }

  void _removeAttachment() {
    _discardAttachment();
    setState(() {
      _pendingImage = null;
      _pendingImagePreview = null;
      _pendingText = null;
    });
  }

  // -------------------------------------------------------------------------
  // 附件选择
  // -------------------------------------------------------------------------

  Future<void> _openAttachments() async {
    if (widget.isGenerating || widget.isSavingInput) return;
    if (_hasAttachment || _picking) return;
    if (ref.read(chatAttachmentsEnabledProvider) == false) {
      AppToast.show(
        context,
        message: context.strings.connectAnAccountInModelsAndUsage,
      );
      return;
    }
    final c = AppColors.of(context);
    final camera = ref.read(mobileImagePickerProvider);
    await AppSheet.show<void>(
      context,
      title: context.strings.addToChat,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              if (camera != null) ...[
                Expanded(
                  child: _sourceTile(
                    c,
                    icon: LucideIcons.camera,
                    label: context.strings.takePhoto,
                    onTap: () {
                      Navigator.of(context).pop();
                      unawaited(_pickImage(camera: true));
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _sourceTile(
                  c,
                  icon: LucideIcons.image,
                  label: context.strings.chooseImage,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(_pickImage(camera: false));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _sourceTile(
                  c,
                  icon: LucideIcons.folderUp,
                  label: context.strings.textFiles,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(_pickTextFile());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceTile(
    AppColors c, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => AppPressable(
    semanticLabel: label,
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: c.fill1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: c.labelPrimary),
          const SizedBox(height: 4),
          Text(
            label,
            key: ValueKey('attachment-source-$label'),
            textAlign: TextAlign.center,
            style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickImage({required bool camera}) async {
    if (_picking || _hasAttachment) return;
    _picking = true;
    try {
      final SelectedImage? choice;
      if (camera) {
        choice = await ref
            .read(mobileImagePickerProvider)!
            .pick(ImageSource.camera);
      } else {
        final mobile = ref.read(mobileImagePickerProvider);
        choice = mobile != null
            ? await mobile.pick(ImageSource.gallery)
            : await ref.read(imageSelectorProvider).select();
      }
      if (choice == null) return;
      final store = await ref.read(attachmentStoreProvider.future);
      final row = await store.importForChat(choice);
      final preview = await store.bytes(row.id);
      if (!mounted) return;
      setState(() {
        _pendingImage = row;
        _pendingImagePreview = preview;
        _pendingText = null;
      });
      widget.focusNode.requestFocus();
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: _attachmentError(error));
      }
    } finally {
      _picking = false;
    }
  }

  Future<void> _pickTextFile() async {
    if (_picking || _hasAttachment) return;
    _picking = true;
    try {
      final choice = await ref.read(textFileSelectorProvider).select();
      if (choice == null || !mounted) return;
      setState(() {
        _pendingText = choice;
        _pendingImage = null;
        _pendingImagePreview = null;
      });
      widget.focusNode.requestFocus();
    } catch (error) {
      if (mounted) {
        AppToast.show(context, message: _attachmentError(error));
      }
    } finally {
      _picking = false;
    }
  }

  String _attachmentError(Object error) => switch (error) {
    AttachmentFailure(code: AttachmentFailureCode.tooLarge) =>
      context.strings.fileTooLargeImagesUpToMb,
    AttachmentFailure(code: AttachmentFailureCode.invalidImage) =>
      context.strings.couldntReadTheImageChooseAStatic,
    _ => context.strings.couldntReadTheFileTryAgain,
  };

  /// 已触发「开始录音」震动的相位，避免 recording 期间重复震动。
  SpeechPhase? _hapticPhase;

  void _startVoice({bool held = false}) {
    if (_capture != null || widget.isGenerating || widget.isSavingInput) return;
    widget.focusNode.unfocus();
    _voiceFeedback.composerHeight = context.size?.height;
    final originSession = ref.read(currentSessionIdProvider);
    final capture = SpeechCaptureController(
      input: ref.read(speechInputProvider),
      hasNetworkRoute: ref.read(speechNetworkRouteProvider),
      waitForRelease: held,
      // 按住模式松开即发：缩短待发窗口，微信式即时反馈。
      autoSendDelay: held
          ? const Duration(milliseconds: 500)
          : const Duration(seconds: 2),
      // Low-end Android devices may need longer than five seconds for a
      // full minute of offline audio. This timer doesn't block rendering.
      finalTimeout: const Duration(seconds: 30),
      submit: (text, id) async {
        if (!mounted || ref.read(currentSessionIdProvider) != originSession) {
          return false;
        }
        return await widget.onVoiceSubmit?.call(text, id) ?? false;
      },
      cancelSubmission: () {
        if (!_disposing) widget.onVoiceCancel?.call();
      },
    );
    setState(() {
      _capture = capture;
      _holding = held;
      _zone = VoiceZone.none;
    });
    _removeListener = capture.addListener((snapshot) {
      if (!mounted || !identical(_capture, capture)) return;
      // 进入录音那一下给清晰的开始震动（每次新录音只震一次）。
      if (snapshot.phase != _hapticPhase) {
        _hapticPhase = snapshot.phase;
        if (snapshot.phase == SpeechPhase.recording) {
          unawaited(HapticFeedback.mediumImpact());
        }
      }
      if (snapshot.phase == SpeechPhase.draft ||
          snapshot.phase == SpeechPhase.sent ||
          snapshot.phase == SpeechPhase.cancelled) {
        if (snapshot.phase == SpeechPhase.draft) {
          _retainDraft(snapshot.text);
          if (_editingVoice && snapshot.text.trim().isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  ref.read(currentSessionIdProvider) == originSession) {
                widget.focusNode.requestFocus();
              }
            });
          }
          if (snapshot.problem != null) {
            // 上屏前经白名单映射：未知 problem 不透传。
            AppToast.show(
              context,
              message: speechProblemMessage(snapshot.problem),
            );
          }
        }
        // Don't dispose a StateNotifier from inside its own notification.
        scheduleMicrotask(() {
          if (mounted && identical(_capture, capture)) _clearCapture();
        });
      }
      _voiceFeedback.refresh();
      setState(() {});
    }, fireImmediately: false);
    unawaited(capture.start());
  }

  void _retainDraft(String text) {
    if (text.isEmpty) return;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onVoiceDraft?.call(text);
    _mode = ChatInputMode.keyboard;
  }

  void _clearCapture() {
    _removeListener?.call();
    _removeListener = null;
    _hapticPhase = null;
    final capture = _capture;
    setState(() {
      _editingVoice = false;
      _capture = null;
      _holding = false;
      _zone = VoiceZone.none;
    });
    capture?.dispose();
  }

  void _useKeyboard() {
    final text = _capture?.snapshot.text ?? '';
    _clearCapture();
    _retainDraft(text);
    setState(() => _mode = ChatInputMode.keyboard);
    widget.focusNode.requestFocus();
  }

  void _accessibleVoice() {
    final capture = _capture;
    if (capture == null) {
      _startVoice();
    } else if (capture.snapshot.phase == SpeechPhase.recording) {
      unawaited(capture.stop());
    }
  }

  void _endHold({bool cancelled = false}) {
    if (!_holding) return;
    final zone = _zone;
    final capture = _capture;
    setState(() {
      _holding = false;
      _zone = VoiceZone.none;
    });
    _voiceFeedback.refresh();
    if (capture == null) return;
    if (cancelled) {
      // 系统打断（来电、下拉通知栏等）不是用户的取消意图：
      // 已识别文本按草稿保留，与生命周期打断的行为一致。
      capture.cancel(keepDraft: true);
    } else if (zone == VoiceZone.cancel) {
      _clearCapture();
    } else if (zone == VoiceZone.revise) {
      _editingVoice = true;
      unawaited(capture.stop(forEditing: true));
    } else {
      unawaited(capture.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final preferred = ref.watch(defaultInputModeProvider);
    ref.listen(defaultInputModeProvider, (_, next) {
      if (_capture != null) _useKeyboard();
      setState(() => _mode = null);
      widget.focusNode.unfocus();
    });
    // 会话切换即放弃待发附件（未发送的图片同步清理暂存文件）。
    ref.listen(currentSessionIdProvider, (_, _) {
      if (_hasAttachment) _removeAttachment();
    });
    final voice = (_mode ?? preferred) == ChatInputMode.voice;
    final canSend = widget.controller.text.trim().isNotEmpty || _hasAttachment;
    final keyboardHold =
        widget.mobile &&
        !voice &&
        !canSend &&
        !widget.focusNode.hasFocus &&
        !widget.isGenerating &&
        !widget.isSavingInput;
    final snapshot = _capture?.snapshot;
    final active = snapshot != null;
    final targetSize = widget.mobile && widget.showModelSelector ? 48.0 : 44.0;
    final inputStyle = AppTextStyles.chatInput.copyWith(color: c.labelPrimary);
    final input = TextField(
      key: const ValueKey('chat-text-input'),
      readOnly: widget.isSavingInput,
      controller: widget.controller,
      focusNode: widget.focusNode,
      minLines: 1,
      maxLines: widget.mobile ? 4 : 6,
      style: inputStyle,
      cursorColor: c.labelPrimary,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _submit(),
      decoration: appInlineInput(
        hintText: keyboardHold
            ? context.strings.holdToTranscribe
            : context.strings.askAnything,
        constraints: BoxConstraints(minHeight: targetSize),
        hintStyle: inputStyle.copyWith(color: c.labelSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
    Widget circle(
      IconData icon,
      String label,
      VoidCallback? action, {
      bool filled = false,
      Key? key,
    }) => Tooltip(
      message: label,
      child: AppPressable(
        key: key,
        minSize: targetSize,
        semanticLabel: label,
        onTap: action,
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: targetSize,
          height: targetSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? c.labelPrimary : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 22,
              color: filled ? c.bgPrimary : c.labelPrimary,
            ),
          ),
        ),
      ),
    );

    final voiceControl = ChatVoiceControl(
      key: _voiceGesture,
      keyboardEntry: keyboardHold && !active,
      enabled: active || (!widget.isSavingInput && !widget.isGenerating),
      phase: snapshot?.phase,
      onAccessibleActivate: _accessibleVoice,
      onStart: () => _startVoice(held: true),
      onMove: (origin, delta) {
        if (!_holding) return;
        final zone = delta.distance < 14
            ? VoiceZone.none
            : voiceZoneAt(_voiceTargets, origin + delta);
        if (zone != _zone) {
          setState(() => _zone = zone);
          _voiceFeedback.refresh();
          if (zone != VoiceZone.none) {
            unawaited(HapticFeedback.selectionClick());
          }
        }
      },
      onEnd: () => _endHold(),
      onCancel: () => _endHold(cancelled: true),
      onTap: () {
        if (active) {
          _accessibleVoice();
        } else if (keyboardHold) {
          widget.focusNode.requestFocus();
        } else {
          AppToast.show(
            context,
            message: context.strings.holdToRecordReleaseToSend,
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(minHeight: targetSize),
        decoration: BoxDecoration(
          color: widget.voiceBounds != null && !active && !keyboardHold
              ? c.fill1.withValues(alpha: .65)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: snapshot == null
            ? Center(
                child: keyboardHold
                    ? const SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.voiceBounds == null
                                ? LucideIcons.audioLines
                                : LucideIcons.mic,
                            size: 18,
                            color: c.labelSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.strings.holdToTalk,
                            style: AppTextStyles.body.copyWith(
                              color: c.labelPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              )
            : const SizedBox.shrink(),
      ),
    );

    final entry = Stack(
      alignment: Alignment.center,
      children: [
        if (!active && (!voice || canSend))
          ExcludeSemantics(excluding: keyboardHold, child: input),
        if (voice && !canSend || keyboardHold)
          SizedBox(width: double.infinity, child: voiceControl),
      ],
    );

    final Widget trailing;
    if (widget.isGenerating) {
      trailing = circle(
        LucideIcons.square,
        context.strings.stopGenerating,
        widget.onStop,
        filled: true,
      );
    } else if (canSend) {
      trailing = circle(
        LucideIcons.arrowUp,
        context.strings.sendMessage,
        widget.isSavingInput ? null : _submit,
        filled: true,
      );
    } else if (voice) {
      trailing = circle(
        LucideIcons.keyboard,
        context.strings.switchToKeyboard,
        _useKeyboard,
        key: const ValueKey('switch-to-keyboard'),
      );
    } else {
      trailing = circle(
        LucideIcons.audioLines,
        context.strings.switchToVoice,
        () {
          widget.focusNode.unfocus();
          setState(() => _mode = ChatInputMode.voice);
        },
        key: const ValueKey('switch-to-voice'),
      );
    }
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        if (active)
          const SingleActivator(LogicalKeyboardKey.escape): _clearCapture,
      },
      child: snapshot != null
          ? ChatVoiceOverlay(
              boundary: widget.voiceBounds,
              press: voiceControl,
              changes: _voiceFeedback,
              stage: (_) => _capture == null
                  ? const SizedBox.shrink()
                  : VoiceRecordingPanel(
                      snapshot: _capture!.snapshot,
                      levels: _capture!.levels,
                      zone: _zone,
                      targets: _voiceTargets,
                      holding: _holding,
                      onActivate: _accessibleVoice,
                      onCancel: _holding ? null : _clearCapture,
                      onEdit: _holding ? null : _useKeyboard,
                    ),
            )
          : GlassSurface(
              key: const ValueKey('chat-composer'),
              radius: 24,
              blur: 16,
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? .80
                  : .84,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasAttachment) _attachmentChip(c),
                  if (widget.showModelSelector)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: entry,
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      circle(
                        LucideIcons.plus,
                        context.strings.addAttachment,
                        _openAttachments,
                        key: const ValueKey('add-attachment'),
                      ),
                      Expanded(
                        child: widget.showModelSelector
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: ChatModelButton(
                                  enabled: !active,
                                  mobile: widget.mobile,
                                  anchorKey: widget.modelAnchorKey,
                                ),
                              )
                            : entry,
                      ),
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
