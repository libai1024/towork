import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:towork/app/assist_provider.dart';
import 'package:towork/app/local_workspace_session.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/app/todo/async_todo_commands.dart';
import 'package:towork/data/local/app_database.dart';
import 'package:towork/data/local/workspace_command_store.dart';
import 'package:towork/domain/assist/quick_assist.dart';
import 'package:towork/domain/models/todo.dart';

Future<void> main() => _start(panel: false);

@pragma('vm:entry-point')
Future<void> assistMain() => _start(panel: true);

/// Built only by the emulator driver. Each run owns its own fixture database.
Future<void> _start({required bool panel}) async {
  WidgetsFlutterBinding.ensureInitialized();
  const run = String.fromEnvironment('TOWORK_SMOKE_RUN');
  if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(run)) {
    throw StateError('Missing smoke run');
  }
  final support = await getApplicationSupportDirectory();
  final dir = await Directory('${support.path}/mobile-smoke/$run')
      .create(recursive: true);
  final phase = File('${dir.path}/created.json');
  final ready = File('${dir.path}/ready.json');
  Future<void> write(File file, Map<String, Object?> value) async {
    final temp = File('${file.path}.$pid.tmp');
    await temp.writeAsString(
      jsonEncode({'run': run, 'pid': pid, ...value}),
      flush: true,
    );
    await temp.rename(file.path);
  }

  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('工作区重启验证'))),
    ),
  );
  try {
    final db = AppDatabase.background(File('${dir.path}/fixture.sqlite'));
    final store = SqliteWorkspaceCommandStore(db);
    final session = LocalWorkspaceSession(store, await store.load());
    final scope = ProviderContainer();
    scope.read(localWorkspaceSessionProvider.notifier).state = session;
    final commands = scope.read(asyncTodoCommandsProvider);
    if (!await phase.exists()) {
      if (Platform.isAndroid && !panel) {
        throw StateError('Expected quick assist first');
      }
      final todo = await commands.create(title: '重启验证', operationId: run);
      await commands.complete([todo.id]);
      await write(phase, {'id': todo.id, 'entry': panel ? 'assist' : 'main'});
      if (panel) {
        await scope
            .read(assistHostProvider)
            .openApp(AssistHandoff(sessionId: run), keepPanel: true);
        return;
      }
    }
    final state = jsonDecode(await phase.readAsString()) as Map;
    final rows = scope.read(todoListProvider);
    final todo = rows.single;
    if (todo.id != state['id'] ||
        todo.status != TodoStatus.done ||
        todo.version != 2) {
      throw StateError('Wrong persisted task');
    }
    if (!await ready.exists()) {
      if (Platform.isAndroid) {
        final peers = scope.read(enginePeersProvider);
        if (!await peers.othersAlive() ||
            (await peers.takeHandoff())?.sessionId != run ||
            await peers.takeHandoff() != null) {
          throw StateError('Quick assist handoff or peer state incorrect');
        }
      }
      await write(ready, {'id': todo.id, 'version': todo.version});
    } else {
      await write(File('${dir.path}/reopened.json'), {
        'id': todo.id,
        'version': todo.version,
      });
    }
  } catch (error, stack) {
    await write(File('${dir.path}/failure.json'), {
      'error': error.toString(),
      'stack': stack.toString(),
    });
    rethrow;
  }
}
