part of 'memory_page.dart';

extension _MemoryListContent on _MemoryPageState {
  Widget _pausedBanner(AppColors c) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
      children: [
        Icon(LucideIcons.shieldOff, size: 16, color: c.labelSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.strings.memoryIsOffNewChatsWontAdd,
            style: AppTextStyles.caption.copyWith(color: c.labelSecondary),
          ),
        ),
        AppPressable(
          semanticLabel: context.strings.resumeMemory,
          onTap: () => _togglePaused(true),
          child: Center(
            child: Text(
              context.strings.close,
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
          title: empty
              ? context.strings.noMemoriesYet
              : context.strings.noMatchingMemories,
          actionLabel: filtered ? context.strings.clearFilters : null,
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
