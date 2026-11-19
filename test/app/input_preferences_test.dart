import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/bootstrap.dart';
import 'package:towork/app/workspace_state.dart';
import 'package:towork/data/services/input_preferences_service.dart';

class _Storage implements InputPreferencesService {
  _Storage({this.value, this.failure});
  final String? value;
  final Object? failure;
  @override
  Future<String?> read() async {
    if (failure case final error?) throw error;
    return value;
  }

  @override
  Future<void> write(String value) async {}
}

void main() {
  test('startup falls back to voice when storage is unavailable', () async {
    final error = StateError('Platform storage is unavailable');
    final result = await loadInputPreference(_Storage(failure: error));
    expect(result.mode, ChatInputMode.voice);
    expect(result.error, same(error));
    expect(
      (await loadInputPreference(_Storage(value: 'keyboard'))).mode,
      ChatInputMode.keyboard,
    );
    expect(
      (await loadInputPreference(_Storage(value: 'unknown'))).mode,
      ChatInputMode.voice,
    );
  });

  test(
    'writes remain ordered and old failure cannot roll back a new selection',
    () async {
      final writes = <ChatInputMode>[];
      final pending = <Completer<void>>[];
      final container = ProviderContainer(
        overrides: [
          inputPreferenceStoreProvider.overrideWithValue((mode) {
            writes.add(mode);
            final operation = Completer<void>();
            pending.add(operation);
            return operation.future;
          }),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(defaultInputModeProvider.notifier);
      final first = controller.select(ChatInputMode.keyboard);
      final firstFailure = expectLater(first, throwsStateError);
      final last = controller.select(ChatInputMode.voice);
      await Future<void>.delayed(Duration.zero);
      expect(writes, [ChatInputMode.keyboard]);
      pending.first.completeError(StateError('First write failed'));
      await firstFailure;
      await Future<void>.delayed(Duration.zero);
      expect(writes, [ChatInputMode.keyboard, ChatInputMode.voice]);
      expect(container.read(defaultInputModeProvider), ChatInputMode.voice);
      pending.last.complete();
      await last;
    },
  );

  test(
    'latest write failure rolls back to the last successfully saved value',
    () async {
      final container = ProviderContainer(
        overrides: [
          inputPreferenceStoreProvider.overrideWithValue((mode) async {
            if (mode == ChatInputMode.voice) throw StateError('Save failed');
          }),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(defaultInputModeProvider.notifier);
      await controller.select(ChatInputMode.keyboard);
      await expectLater(
        controller.select(ChatInputMode.voice),
        throwsStateError,
      );
      expect(container.read(defaultInputModeProvider), ChatInputMode.keyboard);
    },
  );
}
