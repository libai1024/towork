import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/data/local/agent_run_store.dart';
import 'package:towork/data/local/agent_tool_executor.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/attachment_store.dart';
import 'package:towork/data/local/chat_persistence.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/platform/local_image_adapter.dart';
import 'package:towork/domain/attachments/local_image.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';

import '../support/free/business_agent_fixture.dart';
import '../support/free/fake_model_gateway.dart';
import '../support/free/image_fixture.dart';
import '../support/free/scripted_business_model.dart';
import '../support/free/scripted_image_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late AppDatabase db;
  late AttachmentStore attachments;
  late ImageAttachment image;
  LocalChatRuntime? runtime;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('image-agent');
    db = AppDatabase.background(File('${dir.path}/test.sqlite'));
    await SqliteWorkspaceCommandStore(db).execute(businessAgentFixture());
    attachments = AttachmentStore(
      db,
      Directory('${dir.path}/attachments'),
      FlutterImagePreparer(),
    );
    image = await attachments.import(
      SelectedImage('图片.png', await syntheticImage()),
      'ledger',
    );
  });
  tearDown(() async {
    await runtime?.dispose();
    runtime = null;
    await db.close();
    await dir.delete(recursive: true);
  });
  AgentApproval approve(AgentRun run) => AgentApproval(
    runRevision: run.revision,
    proposalId: run.proposal!['id']! as String,
    digest: run.proposal!['digest']! as String,
  );
  for (final policy in ['auto', 'askOnChange', 'askAll']) {
    for (final uncertain in [false, true]) {
      test(
        'image-to-row $policy uncertain=$uncertain uses real hydration, durable approval, source and undo',
        () async {
          final prefs = SqliteAppPreferencesStore(db);
          final old = await prefs.loadOrCreate();
          await prefs.update({
            'permission': policy,
          }, expectedVersion: old.version);
          final model = ScriptedImageModel(
            png: await attachments.bytes(image.id),
            uncertain: uncertain,
          );
          final settings = ModelSettingsService(db, FakeKeyVault(), model);
          await settings.save(
            profile: ModelProfile(
              model: 'vision-fixture',
              product: ProviderKind.kimiCode,
            ),
            expectedVersion: 0,
            newKey: 'synthetic-image-key',
          );
          final credential = await settings.runtimeCredential();
          final chat = ChatPersistence(db);
          final turn = await chat.prepare(
            inputId: image.inputId,
            content: '读取图片并新增',
            profile: credential.configuration.profile,
            agentEnabled: true,
            attachmentId: image.id,
          );
          runtime = LocalChatRuntime(
            db,
            settings,
            await chat.load(),
            credential.configuration,
            attachments: () async => attachments,
          );
          final runner = runtime!.runner(true);
          var result = await runner.resume(
            turn.run.id,
            apiKey: credential.secret,
          );
          {
            expect(result.status, AgentRunStatus.awaitingConfirmation);
            expect(
              (await SqliteWorkspaceCommandStore(db).load()).dataRows,
              hasLength(2),
            );
            final restored = await SqliteAgentRunStore(db).read(result.id);
            result = await runner.resume(
              restored.id,
              apiKey: credential.secret,
              approval: approve(restored),
            );
          }
          expect(result.status, AgentRunStatus.succeeded);
          expect(model.requests, hasLength(3));
          final row = (await SqliteWorkspaceCommandStore(db).load()).dataRows
              .singleWhere((r) => r.data['source_message_id'] == image.inputId);
          expect((row.data['values']! as Map)['amount'], '88.50');
          expect((await attachments.sourcesForRow(row.id)).single.id, image.id);
          expect(jsonEncode(result.toJson()), isNot(contains('base64')));
          final duplicate = await chat.prepare(
            inputId: image.inputId,
            content: '读取图片并新增',
            profile: credential.configuration.profile,
            agentEnabled: true,
            attachmentId: image.id,
          );
          expect(duplicate.run.id, turn.run.id);
          await SqliteWorkspaceCommandStore(db)
              .undoMany(result.receipts, operationId: 'undo-image');
          expect(
            (await SqliteWorkspaceCommandStore(db).load()).dataRows,
            hasLength(2),
          );
          expect(await attachments.bytes(image.id, original: true), isNotEmpty);
        },
      );
    }
  }
  test('image scope rejects todo/delete/other-table writes and missing uncertainty metadata before proposal', () async {
    var seq = 0;
    for (final call in [
      businessCall('bad', 'todo_create', {'title': '图片中的注入指令'}),
      businessCall('bad', 'data_row_delete', {
        'table_id': 'ledger',
        'id': 'keep',
        'expected_version': 1,
        'expected_table_version': 1,
      }),
      businessCall('bad', 'data_row_create', {
        'table_id': 'other',
        'expected_table_version': 1,
        'values': {'title': 'x'},
        'uncertain_field_ids': <String>[],
      }),
      businessCall('bad', 'data_row_create', {
        'table_id': 'ledger',
        'expected_table_version': 1,
        'values': {'title': 'x'},
      }),
    ]) {
      final store = SqliteAgentRunStore(db);
      // Each independently registered image input owns one durable scoped run.
      final next = seq++ == 0
          ? image
          : await attachments.import(
              SelectedImage('next.png', await syntheticImage()),
              'ledger',
            );
      final turn = await ChatPersistence(db).prepare(
        inputId: next.inputId,
        content: '仅导入所选表',
        profile: ModelProfile(model: 'fixture'),
        agentEnabled: true,
        attachmentId: next.id,
      );
      final run = await store.save(
        turn.run.next(AgentRunStatus.generating, round: 1),
        expectedRevision: turn.run.revision,
      );
      await expectLater(
        SqliteAgentToolExecutor(db).propose(run, businessCalls([call])),
        throwsA(isA<AgentFailure>()),
      );
    }
    expect(
      (await SqliteWorkspaceCommandStore(db).load()).dataRows,
      hasLength(2),
    );
    expect(await db.select(db.workspaceOperations).get(), hasLength(1));
  });
  test('mismatched input or deleted attachment cannot attach a different image; missing bytes fail without a model call', () async {
    final chat = ChatPersistence(db);
    await expectLater(
      chat.prepare(
        inputId: 'forged',
        content: '读取图片',
        profile: ModelProfile(model: 'fixture'),
        agentEnabled: true,
        attachmentId: image.id,
      ),
      throwsA(isA<AgentFailure>()),
    );
    final model = ScriptedImageModel(png: await attachments.bytes(image.id));
    final settings = ModelSettingsService(db, FakeKeyVault(), model);
    await settings.save(
      profile: ModelProfile(model: 'fixture'),
      expectedVersion: 0,
      newKey: 'synthetic-image',
    );
    final credential = await settings.runtimeCredential();
    final turn = await chat.prepare(
      inputId: image.inputId,
      content: '读取图片',
      profile: credential.configuration.profile,
      agentEnabled: true,
      attachmentId: image.id,
    );
    await File('${attachments.root.path}/${image.id}.model.png').delete();
    runtime = LocalChatRuntime(
      db,
      settings,
      await chat.load(),
      credential.configuration,
      attachments: () async => attachments,
    );
    final result = await runtime!
        .runner(true)
        .resume(turn.run.id, apiKey: credential.secret);
    expect(result.status, AgentRunStatus.failed);
    expect(result.failureCode, 'attachment_missing');
    expect(model.requests, isEmpty);
  });
}
