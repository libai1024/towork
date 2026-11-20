part of 'todo_detail_sheet.dart';

extension _TodoDetailSource on _TodoDetailSheetState {
  Widget _buildTraceCard(AppColors c, Todo todo) {
    final chatRepo = ref.read(sessionListProvider.notifier);
    final message = chatRepo.messageById(todo.sourceMessageId);
    final session = message == null
        ? null
        : chatRepo.sessionById(message.sessionId);
    final now = DateTime.now();

    if (message == null || session == null) {
      // §6.4 来源消息失效降级
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bgSecondary,
            borderRadius: AppRadii.brXl,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: c.labelSecondary),
              Text(
                context.strings.fromChat,
                style: AppTextStyles.footnote.copyWith(
                  color: c.labelSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                context.strings.originalChatDeleted,
                style: AppTextStyles.caption.copyWith(color: c.labelTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AppPressable(
        onTap: () {
          final source = chatRepo.messageById(todo.sourceMessageId);
          final currentSession = chatRepo.sessionById(source?.sessionId);
          if (currentSession == null) {
            AppToast.show(
              context,
              message: context.strings.originalChatUnavailable,
            );
            return;
          }
          final router = GoRouter.of(context);
          ref.read(currentSessionIdProvider.notifier).state = currentSession.id;
          Navigator.of(context).pop();
          router.go(AppRoutes.home);
        },
        behavior: HitTestBehavior.opaque,
        borderRadius: AppRadii.brXl,
        semanticLabel: context.strings.createdFromChatDoubleTapToView(
          message.content,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bgSecondary,
            borderRadius: AppRadii.brXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 16, color: c.labelSecondary),
                  const SizedBox(width: 8),
                  Text(
                    context.strings.fromChat,
                    style: AppTextStyles.footnote.copyWith(
                      color: c.labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 2,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.labelSecondary,
                      borderRadius: AppRadii.brFull,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '「${message.content}」',
                      style: AppTextStyles.footnote.copyWith(
                        color: c.labelPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${session.title} ${relativeTimeLabel(message.createdAt, now)}',
                      style: AppTextStyles.caption.copyWith(
                        color: c.labelTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: c.labelTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(AppColors c, Todo todo) {
    // 等宽数字：Geist Mono 未随包内置，用 Inter tabular figures 近似（TODO: 接入 Geist Mono asset）。
    final style = AppTextStyles.caption.copyWith(
      color: c.labelTertiary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final lines = <String>[
      context.strings.createdBuildmeta(metaTimeLabel(todo.createdAt)),
      if (todo.updatedAt != null)
        context.strings.updated(metaTimeLabel(todo.updatedAt!)),
      if (todo.completedAt != null)
        context.strings.completedBuildmeta(metaTimeLabel(todo.completedAt!)),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 0.5, color: c.separator),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line, style: style),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
