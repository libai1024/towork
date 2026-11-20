import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/widgets/app_empty_state.dart';
import '../core/widgets/workspace_reading_pane.dart';
import '../features/categories/categories_page.dart';
import '../features/chat/chat_page.dart';
import '../features/data_tables/data_table_detail_page.dart';
import '../features/data_tables/data_tables_page.dart';
import '../features/data_tables/widgets/row_detail_page.dart';
import '../features/memory/memory_page.dart';
import '../features/reports/report_detail_page.dart';
import '../features/reports/reports_page.dart';
import '../features/settings/model_accounts_page.dart';
import 'membership_sheet_page.dart';
import '../features/settings/appearance_page.dart';
import '../features/settings/assistant_preferences_page.dart';
import '../features/settings/quick_assist_settings_page.dart';
import 'model_account_sheet_page.dart';
import '../features/settings/local_profile_page.dart';
import '../features/settings/settings_page.dart';
import '../features/update/update_page.dart';
import '../features/todo/todo_list_page.dart';
import '../features/visualization/visualization_page.dart';
import '../theme/app_spacing.dart';
import '../app/navigation_requests.dart';
import '../app/routes.dart';
import '../app/apple_distribution.dart';
import 'workspace_shell.dart';
import 'startup_update_notice.dart';

/// Null preserves GoRouter's platform-provided initial location.
final initialAppLocationProvider = Provider<String?>((ref) => null);

/// Navigation state lives with the app's ProviderScope, not the Dart process.
/// This keeps app instances and widget tests isolated and disposes listeners.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(
    initialLocation: ref.read(initialAppLocationProvider),
  );
  // 应用层的跳转请求（通知点击、快捷唤醒）由路由器接管；应用层不反向
  // 依赖外壳。
  final requests = ref.read(appNavigationRequestsProvider);
  void go(String location) => router.go(location);
  requests.attach(go);
  ref.onDispose(() {
    requests.detach(go);
    router.dispose();
  });
  return router;
});

GoRouter createAppRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  errorBuilder: (context, state) => const _RouteNotFoundPage(),
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          StartupUpdateNotice(child: WorkspaceShell(child: child)),
      routes: [
        GoRoute(
          name: AppRouteNames.home,
          path: AppRoutes.home,
          builder: (context, state) => const ChatPage(),
        ),
        GoRoute(
          name: AppRouteNames.todos,
          path: AppRoutes.todos,
          builder: (context, state) => TodoListPage(
            notificationTodo: state.uri.queryParameters['notificationTodo'],
            notificationToken: state.uri.queryParameters['notice'],
            notificationKind: state.uri.queryParameters['notificationKind'],
            key: state.pageKey,
            categoryId: state.uri.queryParameters['categoryId'],
          ),
        ),
        GoRoute(
          name: AppRouteNames.categories,
          path: AppRoutes.categories,
          builder: (context, state) => const CategoriesPage(),
        ),
        GoRoute(
          name: AppRouteNames.visualization,
          path: AppRoutes.visualization,
          builder: (context, state) => const VisualizationPage(),
        ),
        GoRoute(
          name: AppRouteNames.reports,
          path: AppRoutes.reports,
          builder: (context, state) => const ReportsPage(),
          routes: [
            GoRoute(
              name: AppRouteNames.reportDetail,
              path: ':id',
              builder: (context, state) => WorkspaceReadingPane(
                child: ReportDetailPage(
                  key: ValueKey('report-${state.pathParameters['id']}'),
                  reportId: state.pathParameters['id']!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          name: AppRouteNames.dataTables,
          path: AppRoutes.dataTables,
          builder: (context, state) => const DataTablesPage(),
          routes: [
            GoRoute(
              name: AppRouteNames.dataTableDetail,
              path: ':id',
              builder: (context, state) => DataTableDetailPage(
                key: ValueKey('table-${state.pathParameters['id']}'),
                tableId: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  name: AppRouteNames.dataRowDetail,
                  path: 'rows/:rowId',
                  builder: (context, state) => WorkspaceReadingPane(
                    child: RowDetailPage(
                      key: state.pageKey,
                      tableId: state.pathParameters['id']!,
                      rowId: state.pathParameters['rowId']!,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          name: AppRouteNames.memory,
          path: AppRoutes.memory,
          builder: (context, state) => const MemoryPage(),
        ),
        GoRoute(
          name: AppRouteNames.settings,
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsPage(),
          routes: [
            GoRoute(
              name: AppRouteNames.membership,
              path: 'membership',
              redirect: (context, state) =>
                  usesAppleDistribution ? AppRoutes.settings : null,
              pageBuilder: membershipSheetPage,
            ),
            GoRoute(
              name: AppRouteNames.update,
              path: 'update',
              builder: (context, state) => const UpdatePage(),
            ),
            GoRoute(
              name: AppRouteNames.localProfile,
              path: 'local-profile',
              pageBuilder: (context, state) => settingsEditorSheetPage(
                context,
                state,
                barrierLabel: context.strings.closeProfile,
                child: const LocalProfilePage(),
              ),
            ),
            GoRoute(
              name: AppRouteNames.assistantPreferences,
              path: 'assistant',
              builder: (context, state) => const AssistantPreferencesPage(),
            ),
            GoRoute(
              name: AppRouteNames.quickAssist,
              path: 'quick-assist',
              builder: (context, state) => const QuickAssistSettingsPage(),
            ),
            GoRoute(
              name: AppRouteNames.modelAccounts,
              path: 'models',
              builder: (context, state) => const ModelAccountsPage(),
              routes: [
                GoRoute(
                  name: AppRouteNames.modelConnection,
                  path: 'edit',
                  pageBuilder: (context, state) =>
                      modelAccountSheetPage(context, state),
                ),
                GoRoute(
                  name: AppRouteNames.modelAccountNew,
                  path: 'new',
                  pageBuilder: (context, state) =>
                      modelAccountSheetPage(context, state, create: true),
                ),
              ],
            ),
            GoRoute(
              name: AppRouteNames.appearance,
              path: 'appearance',
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                transitionDuration: AppMotion.enter,
                reverseTransitionDuration: AppMotion.exit,
                child: const AppearancePage(),
                transitionsBuilder: (context, animation, secondary, child) {
                  if (MediaQuery.disableAnimationsOf(context)) return child;
                  final curved = animation.drive(
                    CurveTween(curve: Curves.easeOut),
                  );
                  return SlideTransition(
                    position: Tween(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(curved),
                    child: FadeTransition(opacity: curved, child: child),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _RouteNotFoundPage extends StatelessWidget {
  const _RouteNotFoundPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('route-not-found'),
    body: SafeArea(
      child: AppEmptyState(
        icon: LucideIcons.fileQuestion,
        title: context.strings.pageNotFound,
        message: context.strings.thisPageMayHaveMovedOrBeen,
        actionLabel: context.strings.backToHome,
        onAction: () => context.go(AppRoutes.home),
      ),
    ),
  );
}
