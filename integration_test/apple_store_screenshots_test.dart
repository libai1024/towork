import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/free_workspace_bootstrap.dart';
import 'package:towork/app/local_database_provider.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/router.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture the released workspace with local sample records', (
    tester,
  ) async {
    final support = await getApplicationSupportDirectory();
    final dir = await support.createTemp('store-capture-');
    final db = AppDatabase.background(File('${dir.path}/capture.sqlite'));
    final state = ProviderContainer(
      overrides: [localDatabaseProvider.overrideWith((ref) async => db)],
    );
    final key = GlobalKey();
    final shots = <String, String>{};
    if (Platform.isMacOS) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      await binding.setSurfaceSize(const Size(1280, 800));
    }
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      await db.close();
      await dir.delete(recursive: true);
    });
    final profile = await db.loadOrCreateProfile();
    await db.renameProfile('小林', expectedVersion: profile.version);
    final now = DateTime.now();
    final titles = ['确认发布日程', '整理访谈笔记', '校对本周报告', '发出评审邀请', '更新设计稿', '汇总会议记录'];
    final store = SqliteWorkspaceCommandStore(db);
    await store.execute(
      WorkspaceCommand(
        operationId: 'store-workspace',
        actions: [
          WorkspaceMutation(
            actionId: 'category',
            kind: WorkspaceEntityKind.category,
            entityId: 'project',
            mutation: WorkspaceMutationKind.create,
            patch: {
              'name': '产品设计',
              'color_value': 0xff885342,
              'icon_key': 'briefcase',
            },
          ),
          for (var i = 0; i < titles.length; i++)
            WorkspaceMutation(
              actionId: 'task$i',
              kind: WorkspaceEntityKind.todo,
              entityId: 'task$i',
              mutation: WorkspaceMutationKind.create,
              patch: {
                'title': titles[i],
                'category_id': 'project',
                'status': i == 5 ? 'done' : 'pending',
                'due_at': DateTime(
                  now.year,
                  now.month,
                  now.day + i ~/ 2,
                  14 + i % 2,
                ).toUtc().toIso8601String(),
              },
            ),
        ],
      ),
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: UncontrolledProviderScope(
          container: state,
          child: const FreeWorkspaceBootstrap(child: ToWorkApp()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final router = state.read(appRouterProvider);
    for (final (name, route) in [
      ('tasks', AppRoutes.todos),
      ('schedule', AppRoutes.visualization),
    ]) {
      router.go(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: tester.view.devicePixelRatio,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      shots[name] = base64Encode(png!.buffer.asUint8List());
      image.dispose();
    }
    binding.reportData = {'screenshots': shots};
  });
}
