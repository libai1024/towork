import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/app_preferences_provider.dart';
import 'package:towork/app/chat_bootstrap_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_profile_provider.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/app/workspace_command_provider.dart';
import 'package:towork/domain/settings/app_preferences.dart';
import 'package:towork/domain/settings/local_profile.dart';
import 'package:towork/features/settings/assistant_preferences_page.dart';
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

void main() {
  late FixturePreferencesStore preferences;
  setUp(() => preferences = FixturePreferencesStore());

  Future<void> mount(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localChatLoaderProvider.overrideWith((ref) async => null),
          appPreferencesStoreProvider.overrideWith((ref) async => preferences),
          workspaceCommandStoreProvider.overrideWith(
            (ref) async => EmptyWorkspaceStore(),
          ),
          localProfileStoreProvider.overrideWith(
            (ref) async => _ProfileStore(),
          ),
          initialAppLocationProvider.overrideWithValue(location),
        ],
        child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('设置页进入助手偏好，保存说明与常用词后摘要随之更新', (tester) async {
    await mount(tester, AppRoutes.settings);
    final row = find.text('助手偏好');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(find.text('未设置'), findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(AssistantPreferencesPage), findsOneWidget);

    // 没有改动时不能保存。
    final save = find.byKey(const ValueKey('save-assistant-instructions'));
    await tester.tap(save);
    await tester.pump();
    expect(preferences.value.customInstructions, '');

    await tester.enterText(
      find.byKey(const ValueKey('assistant-instructions')),
      '  回答简短一点\n称呼我老王  ',
    );
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(preferences.value.customInstructions, '回答简短一点\n称呼我老王');
    expect(find.text('已保存，下一次对话起生效'), findsOneWidget);

    final input = find.byKey(const ValueKey('assistant-word-input'));
    final add = find.byKey(const ValueKey('assistant-word-add'));
    await tester.enterText(input, ' ToWork ');
    await tester.pump();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(preferences.value.speechVocabulary, ['ToWork']);
    expect(find.byKey(const ValueKey('assistant-word-ToWork')), findsOneWidget);
    expect(tester.widget<TextField>(input).controller!.text, isEmpty);

    // 键盘回车同样添加；大小写不同的重复词被拒绝。
    await tester.enterText(input, '嘉立创');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(input, 'towork');
    await tester.pump();
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(preferences.value.speechVocabulary, ['ToWork', '嘉立创']);
    expect(find.text('「towork」已经在列表里'), findsOneWidget);
    expect(find.textContaining('语音词库 2/200'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('删除常用词 ToWork'));
    await tester.pumpAndSettle();
    expect(preferences.value.speechVocabulary, ['嘉立创']);
    expect(find.byKey(const ValueKey('assistant-word-ToWork')), findsNothing);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.byType(AssistantPreferencesPage), findsNothing);
    expect(find.text('已写说明 1 个常用词'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('直接打开路由：载入已保存的内容，说明页讲清每轮发送什么', (tester) async {
    preferences.value = const AppPreferences(
      version: 3,
      customInstructions: '周末不安排工作',
      speechVocabulary: ['ToWork', '周报'],
    );
    await mount(tester, AppRoutes.assistantPreferences);
    expect(find.byType(AssistantPreferencesPage), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AssistantPreferencesPage)),
    );
    expect(
      container
          .read(appRouterProvider)
          .namedLocation(AppRouteNames.assistantPreferences),
      AppRoutes.assistantPreferences,
    );
    expect(find.text('周末不安排工作'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-word-周报')), findsOneWidget);
    expect(find.textContaining('最多 12 条进行中待办'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('摘要文案', () {
    expect(assistantPreferencesSummary(const AppPreferences()), '未设置');
    expect(
      assistantPreferencesSummary(
        const AppPreferences(customInstructions: '  \n '),
      ),
      '未设置',
    );
    expect(
      assistantPreferencesSummary(
        const AppPreferences(customInstructions: '简短'),
      ),
      '已写说明',
    );
    expect(
      assistantPreferencesSummary(
        const AppPreferences(speechVocabulary: ['a', 'b', 'c']),
      ),
      '3 个常用词',
    );
  });
}
