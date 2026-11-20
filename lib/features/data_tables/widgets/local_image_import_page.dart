import 'package:towork/l10n/strings.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/attachment_provider.dart';
import '../../../app/local_chat_runtime.dart';
import '../../../app/providers.dart';
import '../../../app/workspace_state.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/workspace_nav_bar.dart';
import '../../../core/widgets/app_field_label.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../domain/attachments/local_image.dart';
import '../../../domain/ai/agent_run.dart';
import '../../../domain/models/chat.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_text_styles.dart';
import '../../../app/chat/chat_view_model.dart';
import '../../../core/agent/agent_run_card.dart';
import '../../../core/widgets/ai_markdown.dart';

String imageFailureMessage(Object error) => switch (error) {
  AttachmentFailure(code: AttachmentFailureCode.tooLarge) =>
    strings.imageTooLargeChooseAPngOr,
  AttachmentFailure(code: AttachmentFailureCode.invalidImage) =>
    strings.couldntReadThisImageChooseAComplete,
  AttachmentFailure(code: AttachmentFailureCode.missing) =>
    strings.theOriginalAndItsCopyAreUnavailable,
  AttachmentFailure(code: AttachmentFailureCode.inUse) =>
    strings.thisImageIsLinkedToARecognition,
  AttachmentFailure() => strings.couldntReadOrSaveTheImageExisting,
  _ => chatFailureMessage(error),
};

class LocalImageImportPage extends ConsumerStatefulWidget {
  const LocalImageImportPage({super.key, required this.tableId});
  final String tableId;
  @override
  ConsumerState<LocalImageImportPage> createState() =>
      _LocalImageImportPageState();
}

class _LocalImageImportPageState extends ConsumerState<LocalImageImportPage> {
  final _instruction = TextEditingController(
    text: strings.addTheClearlyIdentifiableRecordsToThis,
  );
  List<ImageAttachment> _items = [];
  ImageAttachment? _selected;
  Uint8List? _preview;
  String? _error;
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final store = await ref.read(attachmentStoreProvider.future);
      final items = await store.forTable(widget.tableId);
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = imageFailureMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _work(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = imageFailureMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select(ImageAttachment row) async {
    final store = await ref.read(attachmentStoreProvider.future);
    final preview = await store.bytes(row.id);
    if (mounted) {
      setState(() {
        _selected = row;
        _preview = preview;
      });
    }
  }

  Future<void> _pick() => _work(() async {
    final choice = await ref.read(imageSelectorProvider).select();
    if (choice == null) return;
    final store = await ref.read(attachmentStoreProvider.future);
    final row = await store.import(choice, widget.tableId);
    await _select(row);
    final items = await store.forTable(widget.tableId);
    if (mounted) setState(() => _items = items);
  });
  Future<void> _start() => _work(() async {
    final row = _selected;
    final runtime = ref.read(localChatRuntimeProvider);
    if (row == null || runtime == null || _instruction.text.trim().isEmpty) {
      return;
    }
    if (ref.read(chatViewModelProvider).isGenerating) {
      throw const AgentFailure(AgentFailureCode.conflict);
    }
    final store = await ref.read(attachmentStoreProvider.future);
    await store.bytes(row.id); // Fail locally before creating a model task.
    final credential = await runtime.settings.runtimeCredential();
    final turn = await runtime.persistence.prepare(
      inputId: row.inputId,
      content: strings.imageStart(row.displayName, _instruction.text.trim()),
      profile: credential.configuration.profile,
      agentEnabled: true,
      attachmentId: row.id,
    );
    await runtime.refresh();
    if (!mounted) return;
    ref.read(currentSessionIdProvider.notifier).state = turn.sessionId;
    // The shared view model owns cancellation/configuration and foreground leases.
    unawaited(ref.read(chatViewModelProvider.notifier).resumeRun(turn.run.id));
  });
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    ref.watch(sessionListProvider);
    final generating = ref.watch(chatViewModelProvider).isGenerating;
    final runtime = ref.watch(localChatRuntimeProvider);
    final turn = runtime?.projection.data.turns
        .where((t) => t.inputId == _selected?.inputId)
        .firstOrNull;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: c.bgGround,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, bounds) => Column(
              children: [
                WorkspaceNavBar(
                  title: context.strings.importScreenshot,
                  onBack: () {
                    if (!_busy) Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    children: [
                      Text(
                        context.strings.targetTable(
                          ref
                                  .read(dataTableProvider.notifier)
                                  .tableById(widget.tableId)
                                  ?.name ??
                              context.strings.unavailableBuild,
                        ),
                        style: AppTextStyles.subhead,
                      ),
                      const SizedBox(height: 16),
                      if (_preview != null)
                        ClipRRect(
                          borderRadius: AppRadii.brLg,
                          child: Image.memory(
                            _preview!,
                            height: 220,
                            fit: BoxFit.contain,
                            key: const ValueKey('selected-image-preview'),
                          ),
                        ),
                      if (_selected != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _selected!.displayName,
                          style: AppTextStyles.footnote,
                        ),
                        TextButton(
                          onPressed: () =>
                              showLocalImage(context, ref, _selected!),
                          child: Text(context.strings.viewOriginalImage),
                        ),
                      ],
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_error!, style: AppTextStyles.body),
                        ),
                      if (_busy) const LinearProgressIndicator(),
                      if (turn != null) ...[
                        Text(turn.content, style: AppTextStyles.body),
                        for (final message in turn.messages.where(
                          (m) =>
                              m.role == ChatRole.assistant &&
                              m.type == ChatMessageType.text,
                        ))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: AiMarkdown(text: message.content),
                          ),
                        AgentRunCard(runId: turn.run.id),
                        if (generating &&
                            ref.read(chatViewModelProvider).runId ==
                                turn.run.id)
                          TextButton(
                            onPressed: () => ref
                                .read(chatViewModelProvider.notifier)
                                .cancel(),
                            child: Text(context.strings.stopRecognition),
                          ),
                      ],
                      const SizedBox(height: 12),
                      AppButton(
                        label: context.strings.chooseImage,
                        type: AppButtonType.secondary,
                        enabled: !_busy && !generating,
                        onPressed: _pick,
                        expand: true,
                      ),
                      const SizedBox(height: 24),
                      if (_items.isNotEmpty)
                        Text(
                          context.strings.savedImages,
                          style: AppTextStyles.subhead,
                        ),
                      for (final row in _items)
                        ListTile(
                          title: Text(row.displayName),
                          subtitle: Text(
                            row.state == 'ready'
                                ? context.strings.saved
                                : context.strings.incompleteFileChooseItAgain,
                          ),
                          onTap: _busy || generating
                              ? null
                              : () => _work(() => _select(row)),
                          trailing:
                              runtime?.projection.data.turns.any(
                                    (t) => t.inputId == row.inputId,
                                  ) ==
                                  true
                              ? null
                              : IconButton(
                                  tooltip: context.strings.removeUnusedImage,
                                  icon: const Icon(LucideIcons.trash2),
                                  onPressed: _busy
                                      ? null
                                      : () => _work(() async {
                                          final store = await ref.read(
                                            attachmentStoreProvider.future,
                                          );
                                          await store.removeDraft(row.id);
                                          final items = await store.forTable(
                                            widget.tableId,
                                          );
                                          if (mounted) {
                                            setState(() {
                                              _items = items;
                                              if (_selected?.id == row.id) {
                                                _selected = null;
                                                _preview = null;
                                              }
                                            });
                                          }
                                        }),
                                ),
                        ),
                      if (_error != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  ref.invalidate(attachmentStoreProvider);
                                  unawaited(_load());
                                },
                          child: Text(context.strings.retryReading),
                        ),
                    ],
                  ),
                ),
                if (turn == null && _selected != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: math.max(0, (bounds.maxHeight - 56) * .65),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppFieldLabel(
                            label: context.strings.importInstructions,
                            child: TextField(
                              controller: _instruction,
                              minLines: 1,
                              maxLines: 3,
                              maxLength: 2000,
                              enabled: !_busy,
                              decoration: InputDecoration(
                                hintText: context
                                    .strings
                                    .addRecordsOrSpecifyWhichRecordsTo,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.strings.theImageWillBeSentToThe,
                            style: AppTextStyles.footnote.copyWith(
                              color: c.labelSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label: context.strings.analyzeAndImport,
                            icon: LucideIcons.scanLine,
                            enabled: !_busy && !generating,
                            onPressed: _start,
                            expand: true,
                          ),
                        ],
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

Future<void> showLocalImage(
  BuildContext context,
  WidgetRef ref,
  ImageAttachment image,
) async {
  try {
    final store = await ref.read(attachmentStoreProvider.future);
    final bytes = await store.bytes(image.id, original: true);
    if (!context.mounted) return;
    // Bound the decoded raster by the longer edge: a plain cacheWidth on a
    // very tall portrait shot would still decode a huge bitmap.
    final int? cacheWidth, cacheHeight;
    if (image.width >= image.height) {
      cacheWidth = math.min(image.width, 2048);
      cacheHeight = null;
    } else {
      cacheWidth = null;
      cacheHeight = math.min(image.height, 2048);
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (pageContext) => Scaffold(
          backgroundColor: AppColors.of(pageContext).bgGround,
          body: SafeArea(
            child: Column(
              children: [
                WorkspaceNavBar(
                  title: image.displayName,
                  onBack: () => Navigator.pop(pageContext),
                ),
                Expanded(
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 8,
                      child: Image.memory(
                        bytes,
                        cacheWidth: cacheWidth,
                        cacheHeight: cacheHeight,
                        fit: BoxFit.contain,
                        key: const ValueKey('original-image-view'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } catch (error) {
    if (context.mounted) {
      AppToast.show(context, message: imageFailureMessage(error));
    }
  }
}

class RowImageSources extends ConsumerWidget {
  const RowImageSources({super.key, required this.rowId});
  final String rowId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    icon: const Icon(LucideIcons.image),
    label: Text(context.strings.viewSourceImage),
    onPressed: () async {
      try {
        final store = await ref.read(attachmentStoreProvider.future);
        final sources = await store.sourcesForRow(rowId);
        if (!context.mounted) return;
        if (sources.isEmpty) {
          AppToast.show(
            context,
            message: context.strings.thisRecordHasNoLinkedSourceImage,
          );
          return;
        }
        await showModalBottomSheet<void>(
          context: context,
          builder: (sheetContext) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final source in sources)
                  ListTile(
                    title: Text(source.displayName),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      unawaited(showLocalImage(context, ref, source));
                    },
                  ),
              ],
            ),
          ),
        );
      } catch (error) {
        if (context.mounted) {
          AppToast.show(context, message: imageFailureMessage(error));
        }
      }
    },
  );
}
