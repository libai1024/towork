import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings.dart';
import 'package:towork/domain/settings/model_settings_service.dart';

import '../../support/free/fake_model_gateway.dart';

void main() {
  late Directory dir;
  late File file;
  late AppDatabase db;
  late FakeKeyVault vault;
  late FakeKimiGateway gateway;
  late ModelSettingsService service;
  final profile = ModelProfile(
    model: 'kimi-for-coding',
    product: ProviderKind.kimiCode,
    disableThinking: true,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('towork-config-test-');
    file = File('${dir.path}/app.sqlite');
    db = AppDatabase.background(file);
    vault = FakeKeyVault();
    gateway = FakeKimiGateway();
    service = ModelSettingsService(db, vault, gateway);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  Future<ModelSettingsSnapshot> save() => service.save(
    profile: profile,
    expectedVersion: 0,
    newKey: 'test-only-secret',
  );

  test(
    'configuration reopens without plaintext credentials in SQLite',
    () async {
      await save();
      await db.close();
      expect(
        latin1.decode(await file.readAsBytes()),
        isNot(contains('test-only-secret')),
      );
      db = AppDatabase.background(file);
      service = ModelSettingsService(db, vault, gateway);
      final restored = await service.load();
      expect(restored.hasKey, isTrue);
      expect(restored.configuration.profile.product, ProviderKind.kimiCode);
      expect(restored.configuration.profile.model, 'kimi-for-coding');
      expect(restored.configuration.version, 1);
    },
  );
  test('rotation removes old secret and advances profile revision', () async {
    final old = await save();
    final next = await service.save(
      profile: profile,
      expectedVersion: 1,
      newKey: 'replacement-secret',
    );
    expect(next.configuration.version, 2);
    expect(next.configuration.profile.revision, 2);
    expect(vault.values.containsKey(old.configuration.credentialRef), isFalse);
    expect(vault.values.values, ['replacement-secret']);
    expect(await db.pendingCleanup(), isEmpty);
  });
  test(
    'failed vault write preserves the active configuration and key',
    () async {
      final old = await save();
      vault.failWrite = true;
      await expectLater(
        service.save(
          profile: profile,
          expectedVersion: 1,
          newKey: 'replacement-secret',
        ),
        throwsA(isA<SettingsFailure>()),
      );
      expect(
        (await service.load()).configuration.credentialRef,
        old.configuration.credentialRef,
      );
      expect(vault.values.values, ['test-only-secret']);
    },
  );
  test(
    'failed metadata commit cleans staged secret and preserves old config',
    () async {
      await save();
      final failing = ModelSettingsService(_FailingCommit(db), vault, gateway);
      await expectLater(
        failing.save(
          profile: profile,
          expectedVersion: 1,
          newKey: 'uncommitted-secret',
        ),
        throwsA(isA<SettingsFailure>()),
      );
      expect((await service.load()).configuration.version, 1);
      expect(vault.values.values, ['test-only-secret']);
    },
  );
  test('interrupted pre-commit credential is removed on next load', () async {
    final active = await save();
    await db.stageCredential('interrupted');
    await vault.write('interrupted', 'orphan-secret');
    final restored = await service.load();
    expect(
      restored.configuration.credentialRef,
      active.configuration.credentialRef,
    );
    expect(vault.values.containsKey('interrupted'), isFalse);
  });
  test(
    'key removal persists disablement and retries a failed secure deletion',
    () async {
      await save();
      vault.failDelete = true;
      final removed = await service.deleteKey(expectedVersion: 1);
      expect(removed.hasKey, isFalse);
      expect(removed.cleanupPending, isTrue);
      expect(vault.values, isNotEmpty);
      vault.failDelete = false;
      final retried = await service.load();
      expect(retried.cleanupPending, isFalse);
      expect(vault.values, isEmpty);
    },
  );
  test(
    'concurrent saves with stale version cannot replace newer configuration',
    () async {
      final results = await Future.wait([
        for (var i = 0; i < 2; i++)
          service
              .save(profile: profile, expectedVersion: 0, newKey: 'secret-$i')
              .then<Object>((r) => r, onError: (Object e) => e),
      ]);
      expect(results.whereType<ModelSettingsSnapshot>(), hasLength(1));
      expect(
        results.whereType<SettingsFailure>().single.code,
        SettingsFailureCode.conflict,
      );
      expect(vault.values, hasLength(1));
    },
  );
  test(
    'saved key cannot silently move to another API product or region',
    () async {
      await save();
      for (final changed in [
        ModelProfile(model: 'other'),
        ModelProfile(
          model: 'kimi-for-coding',
          product: ProviderKind.kimiCode,
          region: ProviderRegion.international,
        ),
      ]) {
        await expectLater(
          service.save(profile: changed, expectedVersion: 1),
          throwsA(
            isA<SettingsFailure>().having(
              (e) => e.code,
              'code',
              SettingsFailureCode.missingKey,
            ),
          ),
        );
      }
      expect((await service.load()).configuration.version, 1);
      expect(gateway.calls, 0);
    },
  );
  test(
    'manual probe sends minimal request using the selected profile',
    () async {
      final config = (await save()).configuration;
      final result = await service.testConnection(config, ModelCancellation());
      expect(result.text, 'OK');
      expect(gateway.request!.tools, isEmpty);
      expect(gateway.request!.messages, [
        {'role': 'user', 'content': 'Reply with OK only.'},
      ]);
      expect(gateway.request!.profile.product, ProviderKind.kimiCode);
    },
  );
  test('cancelled request cannot publish a late successful response', () async {
    final config = (await save()).configuration;
    gateway.waitForResponse = Completer<void>();
    final cancel = ModelCancellation();
    final pending = service.testConnection(config, cancel);
    final expectation = expectLater(
      pending,
      throwsA(
        isA<ModelFailure>().having(
          (e) => e.code,
          'code',
          ModelFailureCode.cancelled,
        ),
      ),
    );
    cancel.cancel();
    gateway.waitForResponse!.complete();
    await expectation;
  });
  test(
    'probe result cannot claim success after configuration changed',
    () async {
      final config = (await save()).configuration;
      gateway.waitForResponse = Completer<void>();
      final pending = service.testConnection(config, ModelCancellation());
      final expectation = expectLater(
        pending,
        throwsA(
          isA<SettingsFailure>().having(
            (e) => e.code,
            'code',
            SettingsFailureCode.conflict,
          ),
        ),
      );
      await service.save(
        profile: profile,
        expectedVersion: 1,
        newKey: 'newer-key',
      );
      gateway.waitForResponse!.complete();
      await expectation;
    },
  );
}

class _FailingCommit implements ModelConfigurationStore {
  _FailingCommit(this.db);
  final AppDatabase db;
  @override
  Future<ModelConfiguration> readConfiguration() => db.readConfiguration();
  @override
  Future<void> stageCredential(String ref) => db.stageCredential(ref);
  @override
  Future<List<String>> pendingCleanup() => db.pendingCleanup();
  @override
  Future<void> finishCleanup(String ref) => db.finishCleanup(ref);
  @override
  Future<void> commit(
    ModelConfiguration next, {
    required int expectedVersion,
  }) async => throw const SettingsFailure(SettingsFailureCode.storage);
}
