import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/app_preferences_provider.dart';
import 'package:towork/app/assist_provider.dart';
import 'package:towork/app/chat_bootstrap_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_profile_provider.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/workspace_command_provider.dart';
import 'package:towork/domain/assist/quick_assist.dart';
import 'package:towork/domain/settings/local_profile.dart';
import 'package:towork/features/settings/quick_assist_settings_page.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';

import 'support/free/fake_workspace.dart';

class _ProfileStore implements LocalProfileStore {
  final _profile = LocalProfile(
    id: 'fixture',
    nickname: '测试用户',
    version: 1,
    createdAt: DateTime.utc(2026, 11, 14),
  );
  @override
  Future<LocalProfile> loadOrCreateProfile() async => _profile;
  @override
  Future<LocalProfile> renameProfile(
    String name, {
    required int expectedVersion,
  }) async => _profile;
}

class _Entries implements AssistEntries {
  AssistEntryStatus current = const AssistEntryStatus();
  bool succeed = true;
  final calls = <String>[];

  Future<bool> _call(String name) async {
    calls.add(name);
    return succeed;
  }

  @override
  Future<AssistEntryStatus> status() async {
    calls.add('status');
    return current;
  }

  @override
  Future<bool> openAssistantSettings() => _call('settings');
  @override
  Future<bool> pinShortcut({bool voice = false}) =>
      _call(voice ? 'pin-voice' : 'pin');
  @override
  Future<bool> openPanel() => _call('panel');
}

void main() {
  late _Entries entries;
  setUp(() => entries = _Entries());

  Future<void> mount(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localChatLoaderProvider.overrideWith((ref) async => null),
          appPreferencesStoreProvider.overrideWith(
            (ref) async => FixturePreferencesStore(),
          ),
          workspaceCommandStoreProvider.overrideWith(
            (ref) async => EmptyWorkspaceStore(),
          ),
          localProfileStoreProvider.overrideWith(
            (ref) async => _ProfileStore(),
          ),
          assistEntriesProvider.overrideWithValue(entries),
          initialAppLocationProvider.overrideWithValue(location),
        ],
        child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('没有快捷面板的平台，设置里不出现这一行', (tester) async {
    await mount(tester, AppRoutes.settings);
    expect(find.text('助手偏好'), findsOneWidget);
    expect(find.text('快捷唤醒'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('从设置进入：默认助手、固定到桌面、试用，各自交给系统', (tester) async {
    entries.current = const AssistEntryStatus(
      supported: true,
      defaultAssistant: false,
      canPin: true,
    );
    await mount(tester, AppRoutes.settings);
    final row = find.text('快捷唤醒');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(find.text('未设为默认助手'), findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(QuickAssistSettingsPage), findsOneWidget);
    expect(find.text('未设为默认助手'), findsOneWidget);
    expect(find.textContaining('第三方应用不能接管'), findsOneWidget);

    entries.calls.clear();
    for (final key in [
      'quick-assist-default',
      'quick-assist-pin',
      'quick-assist-pin-voice',
      'quick-assist-try',
    ]) {
      final button = find.byKey(ValueKey(key));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }
    expect(entries.calls, ['settings', 'pin', 'pin-voice', 'panel']);
    expect(find.text('系统快捷功能'), findsOneWidget);
    expect(find.text('华为智控键双触'), findsOneWidget);
    expect(find.textContaining('确认系统的添加提示'), findsOneWidget);

    // 用户在系统设置里改完回来，状态要重新查询。
    entries.current = const AssistEntryStatus(
      supported: true,
      defaultAssistant: true,
      canPin: true,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('quick-assist-default')),
      -300,
    );
    await tester.pumpAndSettle();
    expect(find.text('已设为默认助手'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAssistSettingsPage), findsNothing);
    expect(find.text('已设为默认助手'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('系统拒绝时说明怎么手动完成；桌面不支持固定就不显示那一行', (tester) async {
    entries
      ..current = const AssistEntryStatus(supported: true)
      ..succeed = false;
    await mount(tester, AppRoutes.quickAssist);
    expect(find.byType(QuickAssistSettingsPage), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(QuickAssistSettingsPage)),
    );
    expect(
      container
          .read(appRouterProvider)
          .namedLocation(AppRouteNames.quickAssist),
      AppRoutes.quickAssist,
    );
    expect(find.byKey(const ValueKey('quick-assist-pin')), findsNothing);
    expect(find.byKey(const ValueKey('quick-assist-pin-voice')), findsNothing);
    // 系统不告知是否为默认助手时不显示摘要。
    expect(find.text('未设为默认助手'), findsNothing);
    expect(find.text('已设为默认助手'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('quick-assist-default')));
    await tester.pump();
    expect(find.textContaining('系统设置 → 应用 → 默认应用 里选择 ToWork'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('quick-assist-try')),
      300,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-assist-try')));
    await tester.pump();
    expect(find.text('这台设备上暂时打不开快问面板'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  test('摘要文案', () {
    expect(quickAssistSummary(null), '');
    expect(quickAssistSummary(const AssistEntryStatus(supported: true)), '');
    expect(
      quickAssistSummary(
        const AssistEntryStatus(supported: true, defaultAssistant: true),
      ),
      '已设为默认助手',
    );
    expect(
      quickAssistSummary(
        const AssistEntryStatus(supported: true, defaultAssistant: false),
      ),
      '未设为默认助手',
    );
  });
}
