import 'package:towork/l10n/repository_messages.dart';
import 'package:towork/l10n/strings.dart';

import '../../app/app_preferences_provider.dart';
import '../../app/memory_persistence_provider.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/memory_type_providers.dart';
import '../../app/routes.dart';
import '../../app/workspace_state.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_skeleton.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/workspace_bottom_bar.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/workspace_scope_rail.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/memory_persistence.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'view_models/memory_library.dart';
import 'widgets/memory_detail_sheet.dart';
import 'widgets/memory_edit_sheet.dart';
import 'widgets/memory_list_row.dart';
import 'widgets/memory_sheets.dart';
import 'widgets/memory_type_sheet.dart';

part 'memory_list_content.dart';

/// Narrow type index, compact grouped records, and floating search controls.
class MemoryPage extends ConsumerStatefulWidget {
  const MemoryPage({super.key});
  @override
  ConsumerState<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends ConsumerState<MemoryPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';
  String _typeFilter = 'all';
  MemorySource? _sourceFilter;
  MemoryExpiryFilter _expiryFilter = MemoryExpiryFilter.all;

  /// 生产模式（SQLite 持久化）下的控制器与页面侧镜像；演示模式恒为 null。
  MemoryVaultController? _vault;
  void Function()? _detachVault;
  List<MemoryEntry> _vaultEntries = const [];
  bool _vaultSynced = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _detachVault?.call();
    _detachVault = null;
    _vault = null;
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// 控制器 state 不在 Riverpod 树内（且为受保护成员），页面用监听镜像保持
  /// UI 同步：初次绑定由 fireImmediately 回填字段，后续变更走 setState。
  void _bindVault(MemoryVaultController? vault) {
    if (identical(vault, _vault)) return;
    _detachVault?.call();
    _detachVault = null;
    _vault = vault;
    _vaultEntries = const [];
    _vaultSynced = false;
    if (vault != null) {
      _detachVault = vault.addListener((entries) {
        if (!mounted) return;
        if (_vaultSynced) {
          setState(() => _vaultEntries = entries);
        } else {
          _vaultEntries = entries;
          _vaultSynced = true;
        }
      }, fireImmediately: true);
    }
  }

  String _vaultFailureMessage(MemoryPersistenceFailure failure) =>
      switch (failure.code) {
        MemoryPersistenceFailureCode.paused =>
          context.strings.memoryIsPausedResumeItInSettings,
        MemoryPersistenceFailureCode.validation =>
          context.strings.invalidContentOrType,
        _ => context.strings.couldntSaveTryAgain,
      };

  /// 生产命令包装：失败弹轻提示并返回 false（调用方保留输入/弹层）。
  Future<bool> _runVault(
    Future<void> Function(MemoryVaultController vault) command, {
    String? successMessage,
  }) async {
    final vault = _vault;
    if (vault == null) return false;
    try {
      await command(vault);
    } on MemoryPersistenceFailure catch (failure) {
      if (mounted) {
        AppToast.show(context, message: _vaultFailureMessage(failure));
      }
      return false;
    }
    if (mounted && successMessage != null) {
      AppToast.show(context, message: successMessage);
    }
    return true;
  }

  Future<bool> _productionPaused() async {
    try {
      return await ref.read(memoryPausedViewProvider.future);
    } catch (_) {
      // 读取失败时放行表单，真正的写入会被持久层以 paused 拒绝并提示。
      return false;
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  void _clearFilters() {
    _clearSearch();
    setState(() {
      _typeFilter = 'all';
      _sourceFilter = null;
      _expiryFilter = MemoryExpiryFilter.all;
    });
  }

  Future<void> _addType() async {
    final name = await showMemoryTypeSheet(
      context,
      ref.read(memoryTypesProvider),
    );
    if (name == null || !mounted) return;
    try {
      final kind = ref.read(memoryTypesProvider.notifier).add(name);
      setState(() => _typeFilter = kind.id);
    } on RepositoryException catch (error) {
      AppToast.show(context, message: repositoryErrorMessage(error));
    }
  }

  Future<void> _openEditor({MemoryEntry? existing}) async {
    final vault = _vault;
    if (existing == null) {
      final blocked = vault == null
          ? ref.read(memoryPausedProvider)
          : await _productionPaused();
      if (blocked) {
        if (mounted) {
          AppToast.show(
            context,
            message: context.strings.resumeMemoryToAddAnItem,
          );
        }
        return;
      }
    }
    if (!mounted) return;
    final production = vault != null;
    final draft = await showMemoryEditSheet(
      context,
      existing: existing,
      // 生产模式仅内建 4 类；自定义类型是演示目录的能力。
      kinds: vault == null ? ref.read(memoryTypesProvider) : MemoryKind.builtIn,
      initialKindId: _typeFilter == 'all' ? null : _typeFilter,
      onSave: production ? (value) => _saveVaultDraft(existing, value) : null,
    );
    if (draft == null || !mounted) return;
    // 生产模式已在 onSave 内落库并提示；此处只服务演示内存 store。
    if (production) return;
    final repo = ref.read(memoryListProvider.notifier);
    if (existing == null) {
      repo.addManual(
        content: draft.content,
        type: draft.type,
        customTypeId: draft.customTypeId,
        expiresAt: draft.expiresAt,
      );
      AppToast.show(context, message: context.strings.remembered);
    } else {
      repo.updateEntry(
        existing.copyWith(
          content: draft.content,
          type: draft.type,
          customTypeId: draft.customTypeId,
          expiresAt: draft.expiresAt,
          updatedAt: DateTime.now(),
        ),
      );
      AppToast.show(context, message: context.strings.updatedOpeneditor);
    }
  }

  /// 生产模式保存：成功后弹层才关闭；失败由弹层保留输入并已弹出提示。
  Future<bool> _saveVaultDraft(MemoryEntry? existing, MemoryDraft draft) {
    return _runVault(
      (v) => existing == null
          ? v.addManual(
              content: draft.content,
              type: draft.type,
              customTypeId: draft.customTypeId,
              expiresAt: draft.expiresAt,
            )
          : v.updateEntry(
              existing.copyWith(
                content: draft.content,
                type: draft.type,
                customTypeId: draft.customTypeId,
                expiresAt: draft.expiresAt,
                updatedAt: DateTime.now(),
              ),
            ),
      successMessage: existing == null
          ? context.strings.remembered
          : context.strings.updatedOpeneditor,
    );
  }

  Future<void> _openDetail(MemoryEntry entry) async {
    final kinds = _vault == null
        ? ref.read(memoryTypesProvider)
        : MemoryKind.builtIn;
    final matching = kinds.where((kind) => kind.id == entry.typeScopeId);
    final action = await showMemoryDetailSheet(
      context,
      entry: entry,
      typeLabel: matching.isEmpty
          ? localizedBuiltin(entry.typeLabel)
          : matching.first.isBuiltIn
          ? localizedBuiltin(matching.first.label)
          : matching.first.label,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case MemoryDetailAction.edit:
        await _openEditor(existing: entry);
      case MemoryDetailAction.delete:
        await _deleteEntry(entry);
      case MemoryDetailAction.source:
        _openSourceSession(entry);
      case MemoryDetailAction.copy:
        await copyMemoryContent(entry.content);
        if (mounted) AppToast.show(context, message: context.strings.copied);
    }
  }

  Future<void> _deleteEntry(MemoryEntry entry) async {
    final confirmed = await showDeleteMemoryConfirm(context);
    if (!confirmed || !mounted) return;
    HapticFeedback.mediumImpact();
    final vault = _vault;
    if (vault == null) {
      final repository = ref.read(memoryListProvider.notifier);
      final removed = repository.removeById(entry.id);
      if (removed == null) return;
      AppToast.show(
        context,
        message: context.strings.deleted,
        actionLabel: context.strings.undo,
        duration: const Duration(seconds: 5),
        onAction: () {
          if (repository.mounted) repository.insertAt(removed.$2, removed.$1);
        },
      );
      return;
    }
    final deleted = await _runVault((v) => v.remove(entry.id));
    if (!deleted || !mounted) return;
    // 生产撤销 = 重新记住内容（新 ID），由 addManual 走完整写入校验。
    AppToast.show(
      context,
      message: context.strings.deleted,
      actionLabel: context.strings.rememberAgain,
      duration: const Duration(seconds: 5),
      onAction: () => unawaited(() async {
        try {
          await vault.addManual(
            content: entry.content,
            type: entry.type,
            customTypeId: entry.customTypeId,
            expiresAt: entry.expiresAt,
          );
        } on MemoryPersistenceFailure catch (failure) {
          if (mounted) {
            AppToast.show(context, message: _vaultFailureMessage(failure));
          }
        }
      }()),
    );
  }

  Future<void> _onLongPressMenu(MemoryEntry entry) async {
    HapticFeedback.mediumImpact();
    final action = await showMemoryActionSheet(context);
    if (action == null || !mounted) return;
    switch (action) {
      case MemoryCardAction.edit:
        await _openEditor(existing: entry);
      case MemoryCardAction.copy:
        await copyMemoryContent(entry.content);
        if (mounted) AppToast.show(context, message: context.strings.copied);
      case MemoryCardAction.delete:
        await _deleteEntry(entry);
    }
  }

  void _openSourceSession(MemoryEntry entry) {
    final sessionId = entry.sourceSessionId;
    final sessions = ref.read(sessionListProvider);
    final exists = sessionId != null && sessions.any((s) => s.id == sessionId);
    if (exists) {
      ref.read(currentSessionIdProvider.notifier).state = sessionId;
      context.go(AppRoutes.home);
    } else {
      // 来源会话已删除（§6.4）。
      AppToast.show(
        context,
        message: context.strings.originalChatNoLongerExists,
      );
    }
  }

  Future<void> _togglePaused(bool paused) async {
    if (!paused) {
      final confirmed = await showPauseMemoryConfirm(context);
      if (!confirmed || !mounted) return;
    }
    if (!mounted) return;
    final vault = _vault;
    if (vault == null) {
      final saved = await savePreferences(context, ref, {
        'memory_paused': !paused,
      });
      if (mounted && saved && paused) {
        AppToast.show(context, message: context.strings.memoryRestored);
      }
      return;
    }
    try {
      await vault.setPaused(!paused);
    } on MemoryPersistenceFailure catch (failure) {
      if (mounted) {
        AppToast.show(context, message: _vaultFailureMessage(failure));
      }
      return;
    }
    ref.invalidate(memoryPausedViewProvider);
    if (mounted && paused) {
      AppToast.show(context, message: context.strings.memoryRestored);
    }
  }

  Future<void> _clearAll(int total) async {
    final confirmed = await showClearAllConfirm(context, total);
    if (!confirmed || !mounted) return;
    HapticFeedback.heavyImpact();
    if (_vault == null) {
      ref.read(memoryListProvider.notifier).clearAll();
      AppToast.show(context, message: context.strings.memoryCleared);
      return;
    }
    await _runVault(
      (v) => v.clearAll(),
      successMessage: context.strings.memoryCleared,
    );
  }

  Future<void> _openMoreFilters() async {
    final result = await showMoreFilterSheet(
      context,
      initialSource: _sourceFilter,
      initialExpiry: _expiryFilter,
    );
    if (result != null && mounted) {
      setState(() {
        _sourceFilter = result.$1;
        _expiryFilter = result.$2;
      });
    }
  }

  Future<void> _openMore() async {
    final action = await showMemoryLibraryMenu(context);
    if (!mounted) return;
    if (action == 'filter') {
      await _openMoreFilters();
    } else if (action == 'rules') {
      await showMemoryRules(context);
    } else if (action == 'clear') {
      await _clearAll(
        _vault == null
            ? ref.read(memoryListProvider).length
            : _vaultEntries.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final vaultAsync = ref.watch(memoryVaultProvider);
    final ready = vaultAsync.hasValue && !vaultAsync.hasError;
    final vault = ready ? vaultAsync.value : null;
    _bindVault(vault);
    final all = !ready
        ? const <MemoryEntry>[]
        : vault == null
        ? ref.watch(memoryListProvider)
        : _vaultEntries;
    final kinds = vault == null
        ? ref.watch(memoryTypesProvider)
        : MemoryKind.builtIn;
    final paused = vault == null
        ? ref.watch(memoryPausedProvider)
        : ref.watch(memoryPausedViewProvider).valueOrNull ?? false;
    final library = MemoryLibrary(
      entries: all,
      kinds: kinds,
      now: DateTime.now(),
      selectedId: _typeFilter,
      query: _query,
      source: _sourceFilter,
      expiry: _expiryFilter,
    );
    return Scaffold(
      backgroundColor: c.bgGround,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: WorkspaceNavBar(
            title: context.strings.memoryLibrary,
            onBack: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
            actions: [
              WorkspaceToolbarGroup(
                children: [
                  WorkspaceToolbarAction(
                    icon: paused ? LucideIcons.shieldOff : LucideIcons.brain,
                    label: context.strings.memoryOffModeIs(
                      paused ? context.strings.onLabel : context.strings.close,
                    ),
                    active: paused,
                    onTap: ready ? () => _togglePaused(paused) : null,
                  ),
                  WorkspaceToolbarAction(
                    icon: LucideIcons.ellipsis,
                    label: context.strings.moreActions,
                    active:
                        _sourceFilter != null ||
                        _expiryFilter != MemoryExpiryFilter.all,
                    onTap: ready ? _openMore : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                if (paused) _pausedBanner(c),
                Expanded(
                  child: WorkspaceScopeLayout(
                    items: [
                      WorkspaceScopeItem(
                        id: 'all',
                        label: context.strings.allLabel,
                        count: library.counts['all'],
                      ),
                      for (final kind in kinds)
                        WorkspaceScopeItem(
                          id: kind.id,
                          label: kind.isBuiltIn
                              ? localizedBuiltin(kind.label)
                              : kind.label,
                          count: library.counts[kind.id],
                        ),
                    ],
                    selectedId: _typeFilter,
                    onSelected: (id) => setState(() => _typeFilter = id),
                    onAdd: ready && vault == null ? _addType : null,
                    child: vaultAsync.hasError
                        ? AppEmptyState(
                            icon: LucideIcons.cloudOff,
                            title: context.strings.couldntLoadMemories,
                            actionLabel: context.strings.retry,
                            onAction: () => ref.invalidate(memoryVaultProvider),
                          )
                        : !vaultAsync.hasValue
                        ? _skeleton()
                        : _list(library, all.isEmpty),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: WorkspaceBottomBar(
                searchController: _searchController,
                focusNode: _searchFocus,
                hint: context.strings.searchMemories,
                addLabel: context.strings.newMemory,
                onAdd: ready ? _openEditor : null,
                onClear: _clearSearch,
                onSearchChanged: (value) {
                  setState(() {});
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 250), () {
                    if (mounted) setState(() => _query = value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
