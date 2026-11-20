part of 'todo_list_page.dart';

extension _TodoBoardView on _TodoListPageState {
  Widget _buildBoardView(AppColors c, TodoOverview overview) {
    final now = overview.now;
    final columns = overview.columns;
    final statuses = columns.map((column) => column.status).toList();

    Widget buildColumn(int index) {
      final name = columns[index].title;
      final cards = columns[index].todos;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Text(
                    name,
                    style: AppTextStyles.subhead.copyWith(
                      color: c.labelPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${cards.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: c.labelTertiary,
                    ),
                  ),
                  const Spacer(),
                  AppPressable(
                    onTap: () => _openCreateTodo(statuses[index]),
                    behavior: HitTestBehavior.translucent,
                    semanticLabel: context.strings.newTaskIn(name),
                    child: Icon(
                      LucideIcons.plus,
                      size: 20,
                      color: c.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.inbox,
                            size: 32,
                            color: c.labelQuaternary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.strings.noItems,
                            style: AppTextStyles.footnote.copyWith(
                              color: c.labelTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: cards.length,
                      itemBuilder: (context, i) {
                        final todo = cards[i];
                        final (label, color) = _categoryDisplay(todo);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TodoBoardCard(
                            key: ValueKey(todo.id),
                            todo: todo,
                            now: now,
                            categoryLabel: label,
                            categoryColor: color,
                            onTap: () => _openDetail(todo),
                            onToggleDone: () => _toggleDone(todo),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 620) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 3; i++) Expanded(child: buildColumn(i)),
              ],
            ),
          );
        }
        return PageView.builder(
          controller: _boardCtrl,
          itemCount: 3,
          itemBuilder: (context, index) => buildColumn(index),
        );
      },
    );
  }
}
