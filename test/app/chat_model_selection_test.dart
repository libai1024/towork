import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/app_preferences_provider.dart';
import 'package:towork/app/chat/chat_model_selection.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/app_preferences.dart';
import 'package:towork/domain/settings/model_account_service.dart';
import 'package:towork/domain/settings/model_accounts.dart';
import 'package:towork/domain/settings/model_settings_service.dart';

import '../support/free/fake_model_gateway.dart';

class _FailingService extends ModelAccountService {
  _FailingService(super.settings, super.store, this.beforeFailure);
  final Future<void> Function() beforeFailure;

  @override
  Future<ModelAccountsSnapshot> activate(String id, {String? model}) async {
    await beforeFailure();
    throw StateError('synthetic activation failure');
  }
}

void main() {
  late AppPreferences state;
  late AppPreferencesController preferences;
  late FakeKimiConfigurationStore store;
  late ModelSettingsService settings;

  setUp(() {
    state = const AppPreferences(autoRoute: true);
    preferences = AppPreferencesController(
      current: () => state,
      store: () => null,
      publish: (value) => state = value,
    );
    store = FakeKimiConfigurationStore();
    settings = ModelSettingsService(store, FakeKeyVault(), FakeKimiGateway());
  });

  test(
    'removed account restores automatic routing after failed selection',
    () async {
      await expectLater(
        selectChatModel(
          accounts: ModelAccountService(settings, store),
          preferences: preferences,
          accountId: 'removed',
          model: 'deepseek-v4-pro',
        ),
        throwsException,
      );
      expect(state.autoRoute, isTrue);
      expect(store.activeId, isNull);
    },
  );

  test(
    'successful selection commits the model and disables automatic routing',
    () async {
      final service = ModelAccountService(settings, store);
      final snapshot = await service.save(
        profile: ModelProfile(
          product: ProviderKind.deepseek,
          model: 'deepseek-flash',
        ),
        newKey: 'synthetic-key',
      );
      await selectChatModel(
        accounts: service,
        preferences: preferences,
        accountId: snapshot.activeId!,
        model: 'deepseek-v4-pro',
      );
      expect(store.configuration.profile.model, 'deepseek-v4-pro');
      expect(state.autoRoute, isFalse);
    },
  );

  test('failed selection never overwrites a newer preference edit', () async {
    final service = _FailingService(settings, store, () async {
      await preferences.save({'auto_route': true, 'font_scale': 1.2});
    });
    await expectLater(
      selectChatModel(
        accounts: service,
        preferences: preferences,
        accountId: 'removed',
        model: 'deepseek-v4-pro',
      ),
      throwsStateError,
    );
    expect(state.autoRoute, isTrue);
    expect(state.fontScale, 1.2);
    expect(state.version, 2);
  });
}
