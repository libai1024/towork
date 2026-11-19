import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/attachment_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/model_settings_provider.dart';
import 'package:towork/app/local_chat_runtime.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/notification_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/shell/router.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/app_preferences_store.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/data/platform/local_image_adapter.dart';
import 'package:towork/domain/ai/agent_run.dart';
import 'package:towork/domain/ai/model_gateway.dart';
import 'package:towork/domain/settings/model_settings_service.dart';
import 'package:towork/main.dart';

import '../test/support/free/business_agent_fixture.dart';
import '../test/support/free/fake_model_gateway.dart';
import '../test/support/free/fake_notifications.dart';
import '../test/support/free/image_fixture.dart';
import '../test/support/free/scripted_image_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native image import saves preview, scopes vision, confirms uncertainty, reopens, traces original and undoes',
    (tester) async {
      final dir = await Directory(
        '${(await getApplicationSupportDirectory()).path}/image-ui-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final file = File('${dir.path}/test.sqlite');
      final source = await syntheticImage();
      final selector = FixtureImageSelector(source);
      final model = ScriptedImageModel(
        png: (await FlutterImagePreparer().prepare(source)).modelPng,
        uncertain: true,
      );
      final vault = FakeKeyVault();
      AppDatabase? db;
      ProviderContainer? container;
      DataTableStore data() => container!.read(dataTableProvider.notifier);
      AgentRun latest() => container!
          .read(localChatRuntimeProvider)!
          .projection
          .data
          .turns
          .single
          .run;
      Future<void> until(bool Function() condition) async {
        final watch = Stopwatch()..start();
        while (!condition() && watch.elapsed < const Duration(seconds: 20)) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          condition(),
          isTrue,
          reason:
              'Expected image import state, model calls=${model.requests.length}',
        );
        await tester.pumpAndSettle();
      }

      Future<void> open({bool initial = false}) async {
        final current = AppDatabase.background(file);
        db = current;
        final settings = ModelSettingsService(current, vault, model);
        if (initial) {
          await SqliteWorkspaceCommandStore(current)
              .execute(businessAgentFixture());
          await settings.save(
            profile: ModelProfile(
              model: 'vision-fixture',
              product: ProviderKind.kimiCode,
            ),
            expectedVersion: 0,
            newKey: 'synthetic-native-image',
          );
          final prefs = SqliteAppPreferencesStore(current);
          final old = await prefs.loadOrCreate();
          await prefs.update({
            'permission': 'auto',
            'input_mode': 'keyboard',
          }, expectedVersion: old.version);
        }
        container = ProviderContainer(
          overrides: [
            localDatabaseProvider.overrideWith((ref) async => current),
            modelSettingsServiceProvider.overrideWith((ref) async => settings),
            notificationServiceProvider.overrideWith(
              (ref) => FakeNotifications(),
            ),
            imageSelectorProvider.overrideWithValue(selector),
            initialAppLocationProvider.overrideWithValue(
              AppRoutes.dataTable('ledger'),
            ),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
          ),
        );
        await until(() => container!.read(localChatRuntimeProvider) != null);
      }

      Future<void> close() async {
        AppToast.dismiss();
        await tester.pumpWidget(const SizedBox());
        container?.dispose();
        container = null;
        await db?.close();
        db = null;
      }

      Future<void> tapText(String text) async {
        final finder = find.text(text);
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            200,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(finder.last);
        await tester.tap(finder.last);
        await tester.pumpAndSettle();
      }

      Future<void> importPage() async {
        await tester.tap(find.byTooltip('截图导入'));
        await tester.pumpAndSettle();
        await until(
          () => find.widgetWithText(AppButton, '选择图片').evaluate().isNotEmpty,
        );
      }

      try {
        await open(initial: true);
        await importPage();
        await tapText('选择图片');
        await until(
          () => find
              .byKey(const ValueKey('selected-image-preview'))
              .evaluate()
              .isNotEmpty,
        );
        expect(selector.calls, 1);
        expect(model.requests, isEmpty);
        await tapText('分析并导入');
        await until(
          () =>
              container!
                  .read(localChatRuntimeProvider)!
                  .projection
                  .data
                  .turns
                  .isNotEmpty &&
              latest().status == AgentRunStatus.awaitingConfirmation,
        );
        expect(data().rowsOf('ledger'), hasLength(2));
        expect(model.requests, hasLength(2));
        expect(find.text('图片识别存在不确定字段，请对照原图核对后确认。'), findsOneWidget);
        await close();
        await open();
        await importPage();
        await tapText('验收发票.png');
        await until(
          () => find
              .byKey(const ValueKey('selected-image-preview'))
              .evaluate()
              .isNotEmpty,
        );
        await tapText('全部接受');
        await until(
          () =>
              latest().status == AgentRunStatus.succeeded &&
              data().rowsOf('ledger').length == 3,
        );
        expect(model.requests, hasLength(3));
        // The import route is a fullscreenDialog, so its AppBar leading is a
        // close button; pageBack() would look for a back button and find none.
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
        await tapText('图中发票');
        await tapText('查看来源图片');
        await tapText('验收发票.png');
        await until(
          () => find
              .byKey(const ValueKey('original-image-view'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
        // Row detail uses a custom chevron back button instead of an AppBar
        // leading; tap the control a real user sees.
        await tester.tap(find.byIcon(LucideIcons.chevronLeft));
        await tester.pumpAndSettle();
        await importPage();
        await tapText('验收发票.png');
        await until(() => find.text('撤销').evaluate().isNotEmpty);
        await tapText('撤销');
        await until(
          () =>
              data().rowsOf('ledger').length == 2 &&
              find.text('已撤销本次修改').evaluate().isNotEmpty,
        );
        await close();
        await open();
        await importPage();
        await tapText('验收发票.png');
        await until(() => find.text('已撤销本次修改').evaluate().isNotEmpty);
        expect(data().rowsOf('ledger'), hasLength(2));
        expect(model.requests, hasLength(3));
        await tapText('查看原图');
        await until(
          () => find
              .byKey(const ValueKey('original-image-view'))
              .evaluate()
              .isNotEmpty,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await close();
        await dir.delete(recursive: true);
      }
    },
  );
}
