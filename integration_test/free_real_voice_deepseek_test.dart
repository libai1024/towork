import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/speech_provider.dart';
import 'package:towork/data/ai/openai_compatible_gateway.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/platform/offline_asr_model_store.dart';
import 'package:towork/data/platform/sherpa_speech_input.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/scripted_todo_model.dart';
import 'fixtures/paced_audio.dart';
import 'fixtures/todo_command_wav.dart';

/// Real end-to-end voice chain on a device: the composer's voice button →
/// bundled SenseVoice + VAD (live preview while "speaking") → auto-send →
/// real DeepSeek Agent → durable todo. The microphone is replaced by a
/// real-time replay of a synthesized Mandarin command; everything after the
/// recorder is production code.
///
/// Without a key the Agent talks to the scripted protocol peer, so the voice
/// UI and on-device ASR are still exercised for free. With a key it calls
/// real DeepSeek (a few fen of balance). The key is only a compile-time
/// define for this run; it lives in an in-memory vault and is never printed
/// or written to disk:
///
///     flutter test integration_test/free_real_voice_deepseek_test.dart \
///       -d emulator-5554 --dart-define=DEEPSEEK_API_KEY=sk-...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const apiKey = String.fromEnvironment('DEEPSEEK_API_KEY');

  testWidgets('spoken command becomes an Agent-created todo', (tester) async {
    final support = await getApplicationSupportDirectory();
    Future<void> copy(String asset, String target) => const MethodChannel(
      'towork/assets',
    ).invokeMethod<void>('copyAsset', {'asset': asset, 'target': target});
    final senseVoice = OfflineAsrModelStore(Dio(), root: support);
    final vad = OfflineAsrModelStore(
      Dio(),
      root: support,
      spec: AsrModelSpec.sileroVad,
    );
    await senseVoice.installFromAssets(rootBundle.load, copy: copy);
    await vad.installFromAssets(rootBundle.load, copy: copy);

    // A fresh recorder per call, like production: prepare() probes
    // permission with a throwaway recorder and disposes it.
    final pcm = pcm16FromWav(todoCommandWavBytes());
    final recorders = <PacedRecorder>[];
    PacedRecorder recorder() =>
        recorders.lastWhere((r) => r.started, orElse: () => recorders.last);
    final speech = SherpaSpeechInput(
      loadEngine: () async =>
          SherpaSpeechInput.engineOf(senseVoice, vadPath: vad.modelPath),
      recorderFactory: () async {
        final created = PacedRecorder(pcm);
        recorders.add(created);
        return created;
      },
    );
    await speech.warmUp();
    final events = <String>[];
    speech.events.listen(
      (e) => events.add('${e.kind.name}:${e.text}${e.error?.name ?? ''}'),
    );

    final folder = await Directory(
      '${support.path}/voice-deepseek-${DateTime.now().microsecondsSinceEpoch}',
    ).create();
    final db = AppDatabase.background(File('${folder.path}/e2e.sqlite'));
    final real = apiKey.isNotEmpty;
    final settings = ModelSettingsService(
      db,
      FakeKeyVault(),
      real ? OpenAiCompatibleGateway() : ScriptedTodoModel(),
    );
    await settings.save(
      profile: ModelProfile(
        model: 'deepseek-flash',
        product: ProviderKind.deepseek,
      ),
      expectedVersion: 0,
      newKey: real ? apiKey : 'scripted-voice-key',
    );
    final prefs = SqliteAppPreferencesStore(db);
    final old = await prefs.loadOrCreate();
    await prefs.update({
      'permission': 'auto',
      'input_mode': 'voice',
    }, expectedVersion: old.version);

    final container = ProviderContainer(
      overrides: [
        localDatabaseProvider.overrideWith((ref) async => db),
        modelSettingsServiceProvider.overrideWith((ref) async => settings),
        speechInputProvider.overrideWithValue(speech),
        speechNetworkRouteProvider.overrideWithValue(() async => true),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await speech.dispose();
      await db.close();
    });

    // Never pumpAndSettle during capture: the recording pulse loops.
    Future<void> until(
      bool Function() ready,
      String stage, {
      Duration limit = const Duration(seconds: 20),
    }) async {
      final watch = Stopwatch()..start();
      while (!ready() && watch.elapsed < limit) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final live = find.byKey(const ValueKey('voice-live-text'));
      final shown = live.evaluate().isEmpty
          ? '-'
          : (live.evaluate().first.widget as Text).data;
      expect(
        ready(),
        isTrue,
        reason:
            'stage=$stage; events=$events; live=$shown; '
            'started=${recorders.any((r) => r.started)}; '
            'recorders=${recorders.length}; screen=${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().where((t) => t.trim().isNotEmpty).take(30).toList()}',
      );
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
      ),
    );
    await until(
      () => container.read(localChatRuntimeProvider) != null,
      'bootstrap',
    );
    await tester.pumpAndSettle();

    final clock = Stopwatch()..start();
    await tester.tap(find.byKey(const ValueKey('voice-input')));
    // Live preview: some of the command must be on screen mid-utterance.
    await until(
      () => find.textContaining('明天').evaluate().isNotEmpty,
      'live preview',
    );
    final previewMs = clock.elapsedMilliseconds;
    await until(
      () => recorder().isDrained,
      'audio replay',
      limit: const Duration(seconds: 10),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('voice-input')));
    await tester.tap(find.byKey(const ValueKey('voice-input')));

    await until(
      () =>
          container.read(todoListProvider).isNotEmpty &&
          !container.read(chatViewModelProvider).isGenerating,
      'DeepSeek todo',
      limit: const Duration(seconds: 150),
    );
    await tester.pumpAndSettle();
    final turn = container
        .read(localChatRuntimeProvider)!
        .projection
        .data
        .turns
        .single;
    final todo = container.read(todoListProvider).single;
    // ignore: avoid_print
    print(
      'Voice→${real ? 'DeepSeek' : 'scripted'}: preview at ${previewMs}ms, todo after '
      '${clock.elapsedMilliseconds}ms; transcript="${turn.content}"; '
      'todo="${todo.title}" due=${todo.dueAt}',
    );
    expect(turn.content, contains('周会'), reason: '离线转写应进入对话');
    if (!real) {
      expect(todo.title, '测试任务');
      return;
    }
    expect(todo.title, contains('周会'));
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(todo.dueAt?.day, tomorrow.day, reason: '「明天」应解析为明天');
    expect(todo.dueAt?.hour, 15, reason: '「下午三点」应解析为 15 点');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
