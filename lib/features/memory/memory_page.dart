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
        MemoryPersistenceFailureCode.paused => '记忆已暂停，先在设置里恢复',
        MemoryPersistenceFailureCode.validation => '内容或类型无效',
        _ => '暂时无法保存，请重试',
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
      AppToast.show(context, message: error.message);
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
          AppToast.show(context, message: '免记忆模式下不可新增');
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
      AppToast.show(context, message: '已记住');
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
      AppToast.show(context, message: '已更新');
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
      successMessage: existing == null ? '已记住' : '已更新',
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
      typeLabel: matching.isEmpty ? entry.typeLabel : matching.first.label,
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
        if (mounted) AppToast.show(context, message: '已复制');
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
        message: '已删除',
        actionLabel: '撤销',
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
      message: '已删除',
      actionLabel: '重新记住',
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
        if (mounted) AppToast.show(context, message: '已复制');
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
      AppToast.show(context, message: '原会话已不存在');
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
        AppToast.show(context, message: '已恢复记忆');
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
      AppToast.show(context, message: '已恢复记忆');
    }
  }

  Future<void> _clearAll(int total) async {
    final confirmed = await showClearAllConfirm(context, total);
    if (!confirmed || !mounted) return;
    HapticFeedback.heavyImpact();
    if (_vault == null) {
      ref.read(memoryListProvider.notifier).clearAll();
      AppToast.show(context, message: '记忆库已清空');
      return;
    }
    await _runVault((v) => v.clearAll(), successMessage: '记忆库已清空');
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
            title: '记忆库',
            onBack: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
            actions: [
              WorkspaceToolbarGroup(
                children: [
                  WorkspaceToolbarAction(
                    icon: paused ? LucideIcons.shieldOff : LucideIcons.brain,
                    label: '免记忆模式，当前${paused ? '开启' : '关闭'}',
                    active: paused,
                    onTap: ready ? () => _togglePaused(paused) : null,
                  ),
                  WorkspaceToolbarAction(
                    icon: LucideIcons.ellipsis,
                    label: '更多操作',
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
                        label: '全部',
                        count: library.counts['all'],
                      ),
                      for (final kind in kinds)
                        WorkspaceScopeItem(
                          id: kind.id,
                          label: kind.label,
                          count: library.counts[kind.id],
                        ),
                    ],
                    selectedId: _typeFilter,
                    onSelected: (id) => setState(() => _typeFilter = id),
                    onAdd: ready && vault == null ? _addType : null,
                    child: vaultAsync.hasError
                        ? AppEmptyState(
                            icon: LucideIcons.cloudOff,
                            title: '记忆读取失败',
                            actionLabel: '重试',
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
                hint: '搜索记忆',
                addLabel: '新增记忆',
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

  Widget _pausedBanner(AppColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
      children: [
        Icon(LucideIcons.shieldOff, size: 16, color: c.labelSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '免记忆模式已开启，新对话不会写入记忆库',
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
        ),
        AppPressable(
          semanticLabel: '关闭免记忆模式',
          onTap: () => _togglePaused(true),
          child: Center(
            child: Text(
              '关闭',
              style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _list(MemoryLibrary library, bool empty) {
    if (library.visible.isEmpty) {
      final filtered =
          _query.isNotEmpty ||
          _typeFilter != 'all' ||
          _sourceFilter != null ||
          _expiryFilter != MemoryExpiryFilter.all;
      return Padding(
        padding: const EdgeInsets.only(bottom: 88),
        child: AppEmptyState(
          icon: empty ? LucideIcons.brain : LucideIcons.searchX,
          title: empty ? '还没有记忆' : '暂无相关记忆',
          actionLabel: filtered ? '清除筛选' : null,
          onAction: filtered ? _clearFilters : null,
        ),
      );
    }
    final items = <Object>[
      for (final group in library.groups) ...[group, ...group.entries],
    ];
    final c = AppColors.of(context);
    final now = DateTime.now();
    return ListView.builder(
      key: const ValueKey('memory-record-list'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is MemoryGroup) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 4 : 12, bottom: 2),
            child: Text(
              '${item.kind.label} ${item.entries.length}',
              style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
            ),
          );
        }
        final entry = item as MemoryEntry;
        return MemoryListRow(
          key: ValueKey(entry.id),
          entry: entry,
          now: now,
          highlight: _query,
          onTap: () => _openDetail(entry),
          onLongPress: () => _onLongPressMenu(entry),
        );
      },
    );
  }

  Widget _skeleton() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(8, 4, 16, 88),
    itemCount: 6,
    itemBuilder: (context, index) => const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(height: 15),
          SizedBox(height: 8),
          AppSkeleton(height: 12, width: 112),
        ],
      ),
    ),
  );
}
