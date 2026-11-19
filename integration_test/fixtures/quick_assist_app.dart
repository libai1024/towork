import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/shell/quick_assist_panel.dart';
import 'package:towork/main.dart' as production;
import 'package:towork/shell/quick_assist_app.dart';

import '../../test/support/free/fake_model_gateway.dart';

/// Native two-engine fixture. Build this target only for emulator acceptance.
/// Both activities use a separate SQLite file and an in-memory synthetic key.
Future<void> main() => _start(panel: false);

@pragma('vm:entry-point')
Future<void> assistMain() => _start(panel: true);

Future<void> _start({required bool panel}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final support = await getApplicationSupportDirectory();
  final db = AppDatabase.background(
    File('${support.path}/upgrade-assist-fixture.sqlite'),
  );
  final vault = FakeKeyVault();
  final settings = ModelSettingsService(db, vault, _DelayedReply());
  final config = await db.readConfiguration();
  if (config.credentialRef == null) {
    await settings.save(
      profile: ModelProfile(model: 'assist-fixture'),
      expectedVersion: config.version,
      newKey: 'synthetic-assist-key',
    );
  } else {
    vault.values[config.credentialRef!] = 'synthetic-assist-key';
  }
  final preferences = SqliteAppPreferencesStore(db);
  final current = await preferences.loadOrCreate();
  if (current.inputMode != 'keyboard') {
    await preferences.update({
      'input_mode': 'keyboard',
    }, expectedVersion: current.version);
  }
  runApp(
    ProviderScope(
      overrides: [
        localDatabaseProvider.overrideWith((ref) async => db),
        modelSettingsServiceProvider.overrideWith((ref) async => settings),
      ],
      child: FreeWorkspaceBootstrap(
        legacyInputMode: 'keyboard',
        placeholder: panel
            ? (context, retry) =>
                  QuickAssistApp(home: QuickAssistStartup(retry: retry))
            : null,
        child: panel ? const QuickAssistApp() : const production.ToWorkApp(),
      ),
    ),
  );
}

class _DelayedReply implements ModelGateway {
  @override
  Stream<ModelEvent> stream(
    ModelRequest request, {
    required String apiKey,
    ModelCancellation? cancellation,
  }) async* {
    const text = '快问的后台回复已完成。';
    for (final rune in text.runes) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (cancellation?.isCancelled ?? false) return;
      yield ModelTextDelta(String.fromCharCode(rune));
    }
    yield ModelCompleted(
      assistantMessage: {'role': 'assistant', 'content': text},
      finishReason: 'stop',
    );
  }
}
