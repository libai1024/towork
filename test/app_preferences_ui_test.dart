import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/app_preferences_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/domain/settings/app_preferences.dart';
import 'package:towork/domain/ai/permission_policy.dart';
import 'package:towork/main.dart';

class ControlledPreferences implements AppPreferencesStore {
  AppPreferences value = const AppPreferences(version: 1);
  Completer<void>? pending;
  bool fail = false;
  final List<int> versions = [];
  @override
  Future<AppPreferences> loadOrCreate({
    String legacyInputMode = 'voice',
  }) async => value;
  @override
  Future<AppPreferences> update(
    Map<String, Object?> changes, {
    required int expectedVersion,
  }) async {
    versions.add(expectedVersion);
    await pending?.future;
    if (fail) throw const PreferenceFailure(PreferenceFailureCode.storage);
    if (value.version != expectedVersion) {
      throw const PreferenceFailure(PreferenceFailureCode.conflict);
    }
    return value = value.patch(changes, nextVersion: expectedVersion + 1);
  }
}

void main() {
  test('queued unrelated settings read the last committed revision', () async {
    final store = ControlledPreferences()..pending = Completer<void>();
    var visible = store.value;
    final controller = AppPreferencesController(
      current: () => visible,
      store: () => store,
      publish: (p) => visible = p,
    );
    final first = controller.save({'permission': 'askAll'});
    final second = controller.save({'memory_paused': true});
    await Future<void>.delayed(Duration.zero);
    expect(visible.permission, AiWritePermission.askOnChange);
    expect(store.versions, [1]);
    store.pending!.complete();
    await Future.wait([first, second]);
    expect(store.versions, [1, 2]);
    expect(visible.permission, AiWritePermission.askAll);
    expect(visible.memoryPaused, isTrue);
  });
  test('failed preference save does not poison later retry', () async {
    final store = ControlledPreferences()..fail = true;
    var visible = store.value;
    final controller = AppPreferencesController(
      current: () => visible,
      store: () => store,
      publish: (p) => visible = p,
    );
    await expectLater(
      controller.save({'permission': 'auto'}),
      throwsA(isA<PreferenceFailure>()),
    );
    expect(visible.permission, AiWritePermission.askOnChange);
    store.fail = false;
    await controller.save({'permission': 'askAll'});
    expect(visible.permission, AiWritePermission.askAll);
    expect(store.versions, [1, 1]);
  });
  testWidgets(
    'permission sheet waits for commit, prevents duplicate taps and retries failures',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = ControlledPreferences()..pending = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          initialAppLocationProvider.overrideWithValue(AppRoutes.settings),
        ],
      );
      container.read(activePreferencesStoreProvider.notifier).state = store;
      container.read(appPreferencesSnapshotProvider.notifier).state =
          store.value;
      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ToWorkApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('AI 写入权限'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('自动执行'));
        await tester.pump();
        await tester.tap(find.text('自动执行'));
        await tester.pump();
        expect(store.versions, [1]);
        expect(find.text('正在保存权限…'), findsOneWidget);
        expect(
          container.read(aiWritePermissionProvider),
          AiWritePermission.askOnChange,
        );
        store.fail = true;
        store.pending!.complete();
        await tester.pumpAndSettle();
        expect(find.text('未能保存设置，原设置已保留，请重试'), findsOneWidget);
        expect(find.text('总是询问'), findsOneWidget);
        expect(
          container.read(aiWritePermissionProvider),
          AiWritePermission.askOnChange,
        );
        store.fail = false;
        store.pending = null;
        await tester.tap(find.text('自动执行'));
        await tester.pumpAndSettle();
        expect(find.text('总是询问'), findsNothing);
        expect(
          container.read(aiWritePermissionProvider),
          AiWritePermission.auto,
        );
        expect(store.value.permission, AiWritePermission.auto);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }
    },
  );
}
