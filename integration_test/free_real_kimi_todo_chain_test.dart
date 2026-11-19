import 'dart:async';
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
import 'package:towork/app/workspace_state.dart';
import 'package:towork/app/model_transmission.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/chat/local_chat.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/app/chat/chat_view_model.dart';
import 'package:towork/main.dart';

import '../test/support/free/fake_model_gateway.dart';

/// Real-Kimi acceptance for the basic todo chain. Opt-in only so the default
/// test entry never spends paid quota: run with
///   TOWORK_REAL_KIMI=1 flutter test integration_test/free_real_kimi_todo_chain_test.dart -d macos
/// The key comes from the private .env (KIMI_API_KEY) or the environment and
/// is never printed or persisted outside the disposable in-memory vault.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final appleTest =
      Platform.isIOS && const bool.fromEnvironment('TOWORK_IOS_DEEPSEEK_TEST');
  final enabled = appleTest || Platform.environment['TOWORK_REAL_KIMI'] == '1';
  testWidgets(
    'live model chat UI drives todo create, edit, query, complete, delete confirm and undo',
    (tester) async {
      if (!enabled) {
        // Not a failure: this suite is deliberately excluded from CI.
        return;
      }
      final env = <String, String>{...Platform.environment};
      // The test runs inside the launched app whose working directory is not
      // the repo root; resolve the private .env from an explicit root or by
      // walking up from the cwd looking for the project.
      final roots = <String?>[
        env['TOWORK_PROJECT_ROOT'],
        Directory.current.path,
        for (
          var dir = Directory.current.parent;
          dir.path != dir.parent.path;
          dir = dir.parent
        )
          dir.path,
      ];
      for (final root in appleTest ? <String?>[] : roots) {
        if (root == null) continue;
        final envFile = File('$root/.env');
        if (!await envFile.exists()) continue;
        for (final line in await envFile.readAsLines()) {
          if (line.startsWith('#')) continue;
          final separator = line.indexOf('=');
          if (separator > 0) {
            env.putIfAbsent(
              line.substring(0, separator).trim(),
              () => line.substring(separator + 1).trim(),
            );
          }
        }
        break;
      }
      final apiKey = appleTest
          ? await _simulatorTestKey()
          : env['KIMI_API_KEY']?.trim();
      if (apiKey == null || apiKey.isEmpty) {
        fail('KIMI_API_KEY missing from environment or private .env');
      }
      final model = appleTest
          ? 'deepseek-flash'
          : env['KIMI_CODE_MODEL']?.trim().isNotEmpty == true
          ? env['KIMI_CODE_MODEL']!.trim()
          : 'kimi-for-coding';
      final support = await getApplicationSupportDirectory();
      final directory = await Directory(
        '${support.path}/real-kimi-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${directory.path}/real.sqlite');
      final vault = FakeKeyVault();
      final gateway = createPlatformModelGateway();
      AppDatabase? db;
      ProviderContainer? container;
      final log = <String>[];

      List<LocalChatTurn> turns() =>
          container!
              .read(localChatRuntimeProvider)!
              .projection
              .data
              .turns
              .toList()
            ..sort((a, b) => a.position.compareTo(b.position));
      // Positions restart per session; always judge the active conversation.
      AgentRun latest() {
        final sessionId = container!.read(currentSessionIdProvider);
        final inSession =
            turns().where((t) => t.sessionId == sessionId).toList()
              ..sort((a, b) => a.position.compareTo(b.position));
        return (inSession.isEmpty ? turns() : inSession).last.run;
      }

      List<Todo> todos() => container!.read(todoListProvider);

      Future<void> until(
        bool Function() condition, {
        Duration limit = const Duration(seconds: 150),
        String stage = '',
      }) async {
        final watch = Stopwatch()..start();
        while (!condition() && watch.elapsed < limit) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final runtime = container?.read(localChatRuntimeProvider);
        final statuses = runtime?.projection.data.turns
            .map((t) => t.run.status.name)
            .join(',');
        final hasTurns =
            runtime != null && runtime.projection.data.turns.isNotEmpty;
        final lastFailure = !hasTurns
            ? ''
            : '; lastFailure=${latest().failureCode}';
        expect(
          condition(),
          isTrue,
          reason:
              'stage=$stage; generating='
              '${container?.read(chatViewModelProvider).isGenerating}; error='
              '${container?.read(chatViewModelProvider).error.runtimeType}; '
              'turns=$statuses$lastFailure',
        );
        await tester.pumpAndSettle();
      }

      Future<void> open({
        bool initial = false,
        String permission = 'auto',
      }) async {
        final current = AppDatabase.background(file);
        db = current;
        final settings = ModelSettingsService(current, vault, gateway);
        if (initial) {
          await settings.save(
            profile: ModelProfile(
              model: model,
              product: appleTest
                  ? ProviderKind.deepseek
                  : ProviderKind.kimiCode,
              disableThinking: true,
            ),
            expectedVersion: 0,
            newKey: apiKey,
          );
        }
        final prefs = SqliteAppPreferencesStore(current);
        if (initial) {
          final old = await prefs.loadOrCreate();
          await prefs.update({
            'permission': permission,
            'input_mode': 'keyboard',
          }, expectedVersion: old.version);
        }
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            modelSettingsServiceProvider.overrideWith((ref) async => settings),
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
          stage: 'bootstrap',
        );
      }

      Future<void> close() async {
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      void record(String stage, AgentRun run) {
        log.add(
          jsonEncode({
            'stage': stage,
            'status': run.status.name,
            'rounds': run.round,
            'receipts': run.receipts.length,
            'usage': run.usage,
          }),
        );
        stdout.writeln('Verified stage: $stage (${run.status.name})');
        // Device stdout is not forwarded by `flutter test`; persist evidence
        // next to the app support dir so the runner can read it afterwards.
        unawaited(
          File('${support.path}/real-kimi-acceptance.json')
              .writeAsString('${log.join('\n')}\n'),
        );
      }

      Future<void> send(
        String text, {
        required AgentRunStatus expectStatus,
        required String stage,
      }) async {
        final before = turns().length;
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.tap(input);
        await tester.pumpAndSettle();
        await tester.enterText(input, text);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await until(
          () =>
              !container!.read(chatViewModelProvider).isGenerating &&
              turns().length > before &&
              latest().status == expectStatus,
          stage: stage,
        );
        record(stage, latest());
      }

      Future<void> accept({required String stage}) async {
        final button = find.text('全部接受').last;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await until(
          () =>
              !container!.read(chatViewModelProvider).isGenerating &&
              latest().status == AgentRunStatus.succeeded,
          stage: stage,
        );
        record('$stage-accept', latest());
      }

      try {
        // Tier: 智能确认 — create/edit/complete auto-execute, delete confirms.
        await open(initial: true, permission: 'askOnChange');
        if (appleTest) {
          final profile = ModelProfile(
            model: model,
            product: ProviderKind.deepseek,
          );
          await platformModelAuthorization(
            profile.completionsUri.origin,
            profile.descriptor.label,
          );
        }
        const title = '真实链路验收0924';
        await send(
          '请直接调用工具创建一条待办：标题为「$title」，备注为「真实模型验收专用」。不要向我确认。',
          expectStatus: AgentRunStatus.succeeded,
          stage: 'create',
        );
        await until(
          () => todos().any((t) => t.title == title),
          stage: 'create-visible',
        );
        final created = todos().singleWhere((t) => t.title == title);
        expect(created.note, contains('真实模型验收'));

        await send(
          '请把「$title」的备注改为「已更新」。直接执行，不要确认。',
          expectStatus: AgentRunStatus.succeeded,
          stage: 'edit',
        );
        await until(
          () => todos().singleWhere((t) => t.title == title).note == '已更新',
          stage: 'edit-visible',
        );

        await send(
          '我现在有哪些待办？请只列出标题清单，不要调用写入工具。',
          expectStatus: AgentRunStatus.succeeded,
          stage: 'query',
        );
        expect(todos().length, 1);

        await send(
          '请把「$title」标记为完成。直接执行，不要确认。',
          expectStatus: AgentRunStatus.succeeded,
          stage: 'complete',
        );
        await until(
          () =>
              todos().singleWhere((t) => t.title == title).status ==
              TodoStatus.done,
          stage: 'complete-visible',
        );

        // Smart tier: deletion must wait for explicit approval.
        final turnsBeforeDelete = turns().length;
        await send(
          '请删除待办「$title」。直接调用删除工具。',
          expectStatus: AgentRunStatus.awaitingConfirmation,
          stage: 'delete-propose',
        );
        expect(todos().length, 1, reason: 'smart tier must not delete yet');
        expect(turns().length, turnsBeforeDelete + 1);
        await accept(stage: 'delete');
        await until(() => todos().isEmpty, stage: 'delete-visible');

        // Undo restores the deleted todo locally, without another model call.
        final callsBeforeUndo = turns().length;
        // Earlier succeeded runs also expose undo buttons; take the newest.
        final compactUndo = find.byTooltip('撤销本次全部修改');
        final undo =
            (compactUndo.evaluate().isNotEmpty ? compactUndo : find.text('撤销'))
                .last;
        await tester.ensureVisible(undo);
        await tester.tap(undo);
        await until(
          () => todos().any((t) => t.title == title),
          stage: 'undo-visible',
        );
        expect(turns().length, callsBeforeUndo, reason: 'undo is local only');

        // Kill and reopen: committed state survives without extra model calls.
        final callsBeforeReopen = turns().length;
        await close();
        await open();
        await until(
          () =>
              todos().any((t) => t.title == title) &&
              turns().length == callsBeforeReopen,
          stage: 'reopen',
        );

        // Tier: 总是询问 — even a create must wait for approval. Persisting the
        // preference and remounting keeps the tier read explicit.
        final turnsBeforeAskAll = turns().length;
        final prefs = SqliteAppPreferencesStore(db!);
        final old = await prefs.loadOrCreate();
        await prefs.update({
          'permission': 'askAll',
        }, expectedVersion: old.version);
        await close();
        await open();
        await until(
          () => turns().length == turnsBeforeAskAll,
          stage: 'askall-reopen',
        );
        await send(
          '请直接调用工具创建一条标题为「总问验收0924」的待办。不要向我确认。',
          expectStatus: AgentRunStatus.awaitingConfirmation,
          stage: 'askall-propose',
        );
        expect(
          todos().where((t) => t.title == '总问验收0924'),
          isEmpty,
          reason: 'askAll tier must not write before approval',
        );
        await accept(stage: 'askall');
        await until(
          () => todos().any((t) => t.title == '总问验收0924'),
          stage: 'askall-visible',
        );

        // Free failure path: unreadable credential keeps the input and shows
        // a readable error instead of a half-sent request.
        vault.failRead = true;
        final input = find.byKey(const ValueKey('chat-text-input'));
        await tester.enterText(input, '这条不应发送');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await until(
          () =>
              !container!.read(chatViewModelProvider).isGenerating &&
              container!.read(chatViewModelProvider).error != null,
          stage: 'credential-error',
        );
        expect((tester.widget<TextField>(input)).controller!.text, '这条不应发送');

        stdout.writeln('--- live model acceptance log ---');
        for (final line in log) {
          stdout.writeln(line);
        }
        stdout.writeln('--------------------------------');
        await File('${support.path}/real-kimi-acceptance.json')
            .writeAsString('${log.join('\n')}\n');
        expect(tester.takeException(), isNull);
      } finally {
        gateway.close();
        await close();
        await directory.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

/// The host writes a one-use credential into the isolated simulator's tmp folder.
/// Nothing secret is passed to the compiler or test runner command line.
Future<String> _simulatorTestKey() async {
  final marker = File('${Directory.systemTemp.path}/towork-live-ready');
  final secret = File('${Directory.systemTemp.path}/towork-live-key');
  await marker.create();
  try {
    final limit = Stopwatch()..start();
    while (!await secret.exists() &&
        limit.elapsed < const Duration(minutes: 4)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return (await secret.readAsString()).trim();
  } finally {
    if (await secret.exists()) await secret.delete();
    if (await marker.exists()) await marker.delete();
  }
}
