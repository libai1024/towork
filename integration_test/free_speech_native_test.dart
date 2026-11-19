import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/speech_provider.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/platform/native_speech_input.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/domain/speech/speech_input.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/fake_speech.dart';
import '../test/support/free/scripted_todo_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native speech capability inspection and synthetic voice to durable Agent UI',
    (tester) async {
      // Read-only native boundary: never prompts for permission or opens a mic.
      final native = NativeSpeechInput();
      final capability = await native.inspect('zh-CN');
      debugPrint(
        jsonEncode({
          'speech_inspection': 'passed',
          'available': capability.available,
          'authorized': capability.authorized,
          'locale_count': capability.locales.length,
          'on_device': capability.onDeviceSupported,
        }),
      );
      await native.cancel('inactive-probe');
      await native.dispose();
      final support = await getApplicationSupportDirectory();
      final folder = await Directory(
        '${support.path}/speech-test-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${folder.path}/fixture.sqlite');
      final speech = FakeSpeechInput(), vault = FakeKeyVault();
      final model = ScriptedTodoModel();
      AppDatabase? db;
      ProviderContainer? container;
      // Inline composer waits must not pumpAndSettle blindly: the voice
      // overlay's pulse bars loop forever unless the platform disables
      // animations, so settling during a live capture can stall until the
      // tester timeout on devices. Wait on observable state instead and
      // settle only when no capture is active.
      Future<void> until(bool Function() ready, {bool settle = false}) async {
        final elapsed = Stopwatch()..start();
        while (!ready() && elapsed.elapsed < const Duration(seconds: 10)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(ready(), isTrue);
        await tester.pump(const Duration(milliseconds: 50));
        if (settle) {
          await tester.pumpAndSettle();
        }
      }

      Future<void> open({bool initial = false}) async {
        final current = AppDatabase.background(file);
        db = current;
        final settings = ModelSettingsService(current, vault, model);
        if (initial) {
          await settings.save(
            profile: ModelProfile(
              model: 'fixture',
              product: ProviderKind.kimiCode,
            ),
            expectedVersion: 0,
            newKey: 'synthetic-speech-key',
          );
          final preferences = SqliteAppPreferencesStore(current);
          final old = await preferences.loadOrCreate();
          await preferences.update({
            'permission': 'askAll',
            'input_mode': 'voice',
          }, expectedVersion: old.version);
        }
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            modelSettingsServiceProvider.overrideWith((ref) async => settings),
            speechInputProvider.overrideWithValue(speech),
            speechNetworkRouteProvider.overrideWithValue(() async => true),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
          ),
        );
        await until(
          () => container!.read(localChatRuntimeProvider) != null,
          settle: true,
        );
      }

      Future<void> close() async {
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      try {
        await open(initial: true);
        await tester.tap(find.byKey(const ValueKey('voice-input')));
        await until(() => speech.starts.length == 1);
        final cancelledId = speech.starts.single;
        await tester.ensureVisible(find.byTooltip('取消语音输入'));
        await tester.tap(find.byTooltip('取消语音输入'));
        await until(() => find.byTooltip('取消语音输入').evaluate().isEmpty);
        speech.emit(cancelledId, SpeechEventKind.finalResult, text: '晚到的取消指令');
        await tester.pump(const Duration(seconds: 3));
        expect(container!.read(sessionListProvider), isEmpty);
        expect(model.calls, 0);
        await tester.tap(find.byKey(const ValueKey('voice-input')));
        await until(() => speech.starts.length == 2);
        final id = speech.starts.last;
        expect(id, isNot(cancelledId));
        speech.emit(id, SpeechEventKind.partial, text: '创建测试任务');
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('voice-input')));
        await tester.tap(find.byKey(const ValueKey('voice-input')));
        await until(() => speech.stops.contains(id));
        expect(model.calls, 0);
        speech.emit(id, SpeechEventKind.finalResult, text: '创建测试任务');
        speech.emit(id, SpeechEventKind.finalResult, text: '重复的最终结果');
        await tester.pump(const Duration(milliseconds: 2100));
        await until(() {
          final turns = container!
              .read(localChatRuntimeProvider)!
              .projection
              .data
              .turns;
          return turns.length == 1 &&
              turns.single.run.status == AgentRunStatus.awaitingConfirmation &&
              !container!.read(chatViewModelProvider).isGenerating;
        }, settle: true);
        expect(find.byType(BottomSheet), findsNothing);
        expect(
          container!
              .read(localChatRuntimeProvider)!
              .projection
              .data
              .turns
              .single
              .inputId,
          id,
        );
        expect(container!.read(todoListProvider), isEmpty);
        await tester.ensureVisible(find.text('全部接受'));
        await tester.tap(find.text('全部接受'));
        await until(
          () =>
              container!.read(todoListProvider).length == 1 &&
              !container!.read(chatViewModelProvider).isGenerating,
          settle: true,
        );
        expect(container!.read(todoListProvider).single.title, '测试任务');
        await close();
        await open();
        expect(container!.read(todoListProvider), hasLength(1));
        expect(
          container!
              .read(localChatRuntimeProvider)!
              .projection
              .data
              .turns
              .single
              .inputId,
          id,
        );
        expect(
          container!
              .read(localChatRuntimeProvider)!
              .projection
              .data
              .turns
              .single
              .run
              .receipts,
          hasLength(1),
        );
      } finally {
        await close();
        await speech.bus.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
