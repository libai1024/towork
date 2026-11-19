import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_preferences_provider.dart';
import 'local_chat_runtime.dart';

/// UI-only state shared by the desktop shell and the mobile conversation.
final currentSessionIdProvider = StateProvider<String?>((ref) => null);
final sidebarExpandedProvider = StateProvider<bool>((ref) => true);
final chatModelProvider = StateProvider<String>((ref) {
  final runtime = ref.watch(localChatRuntimeProvider);
  return runtime == null
      ? 'K3'
      : (ref.watch(liveChatConfigurationProvider).valueOrNull ??
                runtime.initialConfiguration)
            .profile
            .model;
});

const desktopBreakpoint = 900.0;

final chatAgentEnabledProvider = StateProvider<bool>((ref) => true);

final chatAdvancedProvider = StateProvider<bool>((ref) {
  final runtime = ref.watch(localChatRuntimeProvider);
  return runtime == null ||
      !(ref.watch(liveChatConfigurationProvider).valueOrNull ??
              runtime.initialConfiguration)
          .profile
          .disableThinking;
});

enum ChatInputMode { voice, keyboard }

/// Storage is injected at startup, so widget tests remain platform-independent.
final inputPreferenceStoreProvider =
    Provider<Future<void> Function(ChatInputMode)?>(
      (ref) => (mode) async {
        await ref.read(appPreferencesControllerProvider).save({
          'input_mode': mode.name,
        });
      },
    );
final initialInputModeProvider = Provider<ChatInputMode>(
  (ref) => ChatInputMode.values.byName(
    ref.watch(appPreferencesSnapshotProvider.select((p) => p.inputMode)),
  ),
);
final defaultInputModeProvider =
    StateNotifierProvider<InputModePreference, ChatInputMode>(
      (ref) => InputModePreference(
        ref.watch(initialInputModeProvider),
        ref.watch(inputPreferenceStoreProvider),
      ),
    );

class InputModePreference extends StateNotifier<ChatInputMode> {
  InputModePreference(super.initial, this.save) : _persisted = initial;
  final Future<void> Function(ChatInputMode)? save;
  ChatInputMode _persisted;
  Future<void> _pending = Future<void>.value();
  int _revision = 0;

  /// Publish after ordered writes commit; failures preserve the saved value.
  /// An earlier failed write must never overwrite a later user selection.
  Future<void> select(ChatInputMode value) async {
    if (!mounted) return;
    final revision = ++_revision;
    final operation = _pending.then((_) async {
      try {
        await save?.call(value);
        _persisted = value;
        if (mounted) state = value;
      } catch (_) {
        if (mounted && revision == _revision) state = _persisted;
        rethrow;
      }
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    await operation;
  }
}
