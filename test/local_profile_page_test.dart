import 'package:towork/app/chat_bootstrap_provider.dart';
import 'package:towork/app/app_preferences_provider.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_profile_provider.dart';
import 'package:towork/app/workspace_command_provider.dart';

import 'support/free/fake_workspace.dart';

import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/domain/settings/local_profile.dart';
import 'package:towork/features/settings/local_profile_page.dart';
import 'package:towork/main.dart';
import 'package:towork/theme/app_theme.dart';

class FixtureProfileStore implements LocalProfileStore {
  LocalProfile profile = LocalProfile(
    id: 'stable-fixture-id',
    nickname: '原用户名',
    version: 1,
    createdAt: DateTime.utc(2026, 9, 23),
  );
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<LocalProfile> loadOrCreateProfile() async {
    if (fail) throw const ProfileFailure(ProfileFailureCode.storage);
    return profile;
  }

  @override
  Future<LocalProfile> renameProfile(
    String name, {
    required int expectedVersion,
  }) async {
    await pending?.future;
    if (fail) throw const ProfileFailure(ProfileFailureCode.storage);
    if (expectedVersion != profile.version) {
      throw const ProfileFailure(ProfileFailureCode.conflict);
    }
    profile = LocalProfile(
      id: profile.id,
      nickname: normalizeNickname(name),
      version: profile.version + 1,
      createdAt: profile.createdAt,
    );
    return profile;
  }
}

void main() {
  late FixtureProfileStore store;
  setUp(() => store = FixtureProfileStore());
  testWidgets('settings opens profile and shows saved nickname on return', (
    tester,
  ) async {
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
          localProfileStoreProvider.overrideWith((ref) async => store),
          initialAppLocationProvider.overrideWithValue(AppRoutes.settings),
        ],
        child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('原用户名'));
    await tester.pumpAndSettle();
    expect(find.byType(LocalProfilePage), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LocalProfilePage)),
    );
    expect(
      container
          .read(appRouterProvider)
          .namedLocation(AppRouteNames.localProfile),
      AppRoutes.localProfile,
    );
    await tester.enterText(
      find.byKey(const ValueKey('local-nickname-input')),
      '流程测试用户',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-local-profile')));
    await tester.pumpAndSettle();
    expect(find.text('用户名已保存到此设备'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('流程测试用户'), findsWidgets);
    expect(find.byType(LocalProfilePage), findsNothing);
    expect(store.profile.id, 'stable-fixture-id');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'production bootstrap scopes empty persisted stores without demo seeds',
    (tester) async {
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
            localProfileStoreProvider.overrideWith((ref) async => store),
            initialAppLocationProvider.overrideWithValue(AppRoutes.todos),
          ],
          child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ToWorkApp)),
      );
      expect(container.read(todoListProvider), isEmpty);
      expect(container.read(categoryListProvider), isEmpty);
      expect(find.text('暂无待办'), findsOneWidget);
    },
  );

  Future<ProviderContainer> mount(WidgetTester tester) async {
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
          localProfileStoreProvider.overrideWith((ref) async => store),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LocalProfilePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(LocalProfilePage)),
    );
  }

  testWidgets('nickname is published only after committed save', (
    tester,
  ) async {
    final container = await mount(tester);
    store.pending = Completer<void>();
    await tester.enterText(
      find.byKey(const ValueKey('local-nickname-input')),
      '新用户名',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-local-profile')));
    await tester.pump();
    expect(container.read(userProfileProvider).nickname, '原用户名');
    store.pending!.complete();
    await tester.pumpAndSettle();
    expect(container.read(userProfileProvider).nickname, '新用户名');
    expect(container.read(userProfileProvider).tier, '免费版');
    expect(
      container.read(localProfileSnapshotProvider)!.id,
      'stable-fixture-id',
    );
    expect(find.text('用户名已保存到此设备'), findsOneWidget);
  });
  testWidgets('failed save retains the prior name and can be retried', (
    tester,
  ) async {
    final container = await mount(tester);
    store.fail = true;
    await tester.enterText(
      find.byKey(const ValueKey('local-nickname-input')),
      '新名字',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-local-profile')));
    await tester.pumpAndSettle();
    expect(container.read(userProfileProvider).nickname, '原用户名');
    expect(find.textContaining('暂时无法读取或保存'), findsOneWidget);
    store.fail = false;
    await tester.tap(find.byKey(const ValueKey('save-local-profile')));
    await tester.pumpAndSettle();
    expect(container.read(userProfileProvider).nickname, '新名字');
  });
  testWidgets(
    'startup failure offers recovery without exposing a fake workspace',
    (tester) async {
      store.fail = true;
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
            localProfileStoreProvider.overrideWith((ref) async => store),
          ],
          child: const FreeWorkspaceBootstrap(
            child: MaterialApp(home: Text('工作台已打开')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('工作台已打开'), findsNothing);
      expect(find.textContaining('原有数据已保留'), findsOneWidget);
      store.fail = false;
      await tester.tap(find.text('重新打开'));
      await tester.pumpAndSettle();
      expect(find.text('工作台已打开'), findsOneWidget);
    },
  );

  testWidgets('leaving the page during commit still refreshes shared profile', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
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
          localProfileStoreProvider.overrideWith((ref) async => store),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (_, shown, _) =>
                shown ? const LocalProfilePage() : const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LocalProfilePage)),
    );
    store.pending = Completer<void>();
    await tester.enterText(
      find.byKey(const ValueKey('local-nickname-input')),
      '离开后提交',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-local-profile')));
    await tester.pump();
    visible.value = false;
    await tester.pump();
    store.pending!.complete();
    await tester.pumpAndSettle();
    expect(container.read(userProfileProvider).nickname, '离开后提交');
    expect(tester.takeException(), isNull);
  });
}
