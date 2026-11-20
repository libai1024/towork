import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart' hide DataRow;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/workspace_clock.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/workspace_action_menu.dart';
import '../../core/widgets/workspace_bottom_bar.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../domain/models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../core/todo/create_todo_sheet.dart';
import 'view_models/schedule_overview.dart';
import 'viz_stats.dart';
import 'widgets/calendar_card.dart';
import 'widgets/distribution_card.dart';
import 'widgets/heatmap_card.dart';
import 'widgets/schedule_agenda.dart';
import 'widgets/trend_card.dart';

/// The default calendar agenda reads the shared repositories. Analysis views and
/// the draggable calendar remain available from the view menu.
class VisualizationPage extends ConsumerStatefulWidget {
  const VisualizationPage({super.key});

  @override
  ConsumerState<VisualizationPage> createState() => _VisualizationPageState();
}

class _VisualizationPageState extends ConsumerState<VisualizationPage> {
  _VizView _view = _VizView.schedule;
  final Set<String> _selectedRoots = {};
  final _searchController = TextEditingController();
  String _query = '';
  DateTime? _day;
  bool _weekOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleRoot(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedRoots.contains(id)) {
        _selectedRoots.remove(id);
      } else {
        _selectedRoots.add(id);
      }
    });
  }

  void _isolateRoot(String? rootId) {
    if (rootId == null) return;
    HapticFeedback.lightImpact();
    setState(
      () => _selectedRoots
        ..clear()
        ..add(rootId),
    );
  }

  void _showFilters(List<Category> roots) {
    AppSheet.show<void>(
      context,
      title: context.strings.filterCategories,
      child: StatefulBuilder(
        builder: (context, updateSheet) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuRow(
                label: context.strings.allLabel,
                selected: _selectedRoots.isEmpty,
                onTap: () {
                  setState(_selectedRoots.clear);
                  updateSheet(() {});
                },
              ),
              for (final root in roots)
                _MenuRow(
                  label: root.name,
                  selected: _selectedRoots.contains(root.id),
                  onTap: () {
                    _toggleRoot(root.id);
                    updateSheet(() {});
                  },
                ),
              _MenuRow(
                label: context.strings.complete,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showViews(BuildContext anchor) async {
    final choice = await showWorkspaceActionMenu<String>(
      anchor,
      selected: _view.name,
      items: [
        for (final view in _VizView.values)
          (value: view.name, label: view.label, icon: view.icon),
        (
          value: 'today',
          label: anchor.strings.backToToday,
          icon: LucideIcons.calendarCheck,
        ),
        (
          value: 'chat',
          label: anchor.strings.askAi,
          icon: LucideIcons.messageCircle,
        ),
      ],
    );
    if (!mounted || choice == null) return;
    if (choice == 'chat') {
      context.go(AppRoutes.home);
    } else if (choice == 'today') {
      setState(() {
        _day = null;
        _view = _VizView.schedule;
      });
    } else {
      setState(() => _view = _VizView.values.byName(choice));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final now = ref.watch(workspaceClockProvider).now;
    final todos = ref.watch(todoListProvider);
    final categories = ref.watch(categoryListProvider);
    final roots =
        categories.where((c) => c.parentId == null && !c.archived).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final activeRoots = _selectedRoots.intersection(
      roots.map((c) => c.id).toSet(),
    );
    final day = _day ?? dayOnly(now);
    final data = ScheduleOverview.from(
      todos: todos,
      categories: categories,
      day: day,
      now: now,
      selectedRoots: activeRoots,
      search: _query,
    );
    final filtered = filterTodosByRoots(todos, activeRoots, categories)
        .where(
          (todo) =>
              _query.trim().isEmpty ||
              todo.title.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(
              title: context.strings.scheduleOverview,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
              actions: [
                WorkspaceToolbarGroup(
                  children: [
                    WorkspaceToolbarAction(
                      icon: LucideIcons.listFilter,
                      label: context.strings.filterCategories,
                      active: activeRoots.isNotEmpty,
                      onTap: () => _showFilters(roots),
                    ),
                    Builder(
                      builder: (anchor) => WorkspaceToolbarAction(
                        icon: _view.icon,
                        label: context.strings.switchScheduleView,
                        active: _view != _VizView.schedule,
                        onTap: () => _showViews(anchor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: _view == _VizView.schedule
                  ? ScheduleAgenda(
                      data: data,
                      weekOnly: _weekOnly,
                      searching: _query.trim().isNotEmpty,
                      onWeekModeChanged: (value) =>
                          setState(() => _weekOnly = value),
                      onSelected: (date) => setState(() => _day = date),
                    )
                  : _buildAnalysis(
                      filtered,
                      categories,
                      ref.watch(dataTableProvider).rows,
                    ),
            ),
            WorkspaceBottomBar(
              searchController: _searchController,
              onSearchChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              onAdd: () => AppSheet.show<void>(
                context,
                child: CreateTodoSheet(
                  categoryId: activeRoots.length == 1
                      ? activeRoots.single
                      : null,
                  dueAt: DateTime(day.year, day.month, day.day, 18),
                ),
              ),
              addLabel: context.strings.createTaskOnSelectedDate,
              hint: context.strings.searchSchedule,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysis(
    List<Todo> todos,
    List<Category> categories,
    List<DataRow> dataRows,
  ) {
    final card = switch (_view) {
      _VizView.heatmap => HeatmapCard(todos: todos, dataRows: dataRows),
      _VizView.calendar => CalendarCard(todos: todos, categories: categories),
      _VizView.distribution => DistributionCard(
        slices: distributionSlices(todos, categories),
        onIsolate: _isolateRoot,
      ),
      _VizView.trend => TrendCard(todos: todos),
      _VizView.schedule => const SizedBox.shrink(),
    };
    return ListView(
      key: ValueKey(_view),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [card],
    );
  }
}

enum _VizView {
  schedule('日程', LucideIcons.calendarDays),
  heatmap('热力图', LucideIcons.grid2x2),
  calendar('日历', LucideIcons.calendar),
  distribution('分布', LucideIcons.chartPie),
  trend('趋势', LucideIcons.trendingUp);

  const _VizView(this._label, this.icon);
  final IconData icon;
  final String _label;
  String get label => localizedBuiltin(_label);
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      selected: selected,
      child: AppPressable(
        semanticLabel: label,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                ),
              ),
              if (selected)
                Icon(LucideIcons.check, size: 18, color: c.labelPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
