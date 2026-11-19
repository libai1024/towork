import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Stable route names for integrations and path builders for in-app navigation.
abstract final class AppRouteNames {
  static const home = 'home';
  static const todos = 'todos';
  static const categories = 'categories';
  static const visualization = 'visualization';
  static const reports = 'reports';
  static const reportDetail = 'report-detail';
  static const dataTables = 'data-tables';
  static const dataTableDetail = 'data-table-detail';
  static const dataRowDetail = 'data-row-detail';
  static const memory = 'memory';
  static const settings = 'settings';
  static const membership = 'membership';
  static const modelAccounts = 'model-accounts';
  static const modelConnection = 'model-connection';
  static const modelAccountNew = 'model-account-new';
  static const localProfile = 'local-profile';
  static const appearance = 'appearance';
  static const assistantPreferences = 'assistant-preferences';
  static const quickAssist = 'quick-assist';
  static const update = 'update';
}

abstract final class AppRoutes {
  static const home = '/';
  static const todos = '/todos';
  static const categories = '/categories';
  static const visualization = '/visualization';
  static const reports = '/reports';
  static const dataTables = '/data-tables';
  static const memory = '/memory';
  static const settings = '/settings';
  static const membership = '$settings/membership';

  /// 模型与额度：账户列表、实时额度、路由。
  static const modelAccounts = '$settings/models';

  /// 编辑当前账户（没有任何账户时等同于新建）。
  static const modelConnection = '$modelAccounts/edit';
  static const modelAccountNew = '$modelAccounts/new';
  static const localProfile = '$settings/local-profile';
  static const appearance = '$settings/appearance';

  /// 助手偏好：长期说明与常用词。
  static const assistantPreferences = '$settings/assistant';

  /// 快捷唤醒：默认助手、桌面快捷方式等入口。
  static const quickAssist = '$settings/quick-assist';
  static const update = '$settings/update';

  static String todosForCategory(String categoryId) =>
      Uri(path: todos, queryParameters: {'categoryId': categoryId}).toString();

  static String modelAccount(String id) =>
      Uri(path: modelConnection, queryParameters: {'id': id}).toString();

  static String report(String id) => _path(['reports', id]);
  static String dataTable(String id) => _path(['data-tables', id]);
  static String dataRow(String tableId, String rowId) =>
      _path(['data-tables', tableId, 'rows', rowId]);

  static String _path(List<String> segments) {
    if (segments.any((segment) => segment.isEmpty)) {
      throw ArgumentError.value(segments, 'segments', 'Must not be empty');
    }
    return '/${segments.map(Uri.encodeComponent).join('/')}';
  }
}

/// Page-level back navigation also works after opening a top-level deep link.
/// Modal sheets continue to pop their own Navigator directly.
extension AppNavigation on BuildContext {
  void popOrGo(String fallback) {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(fallback);
    }
  }
}
