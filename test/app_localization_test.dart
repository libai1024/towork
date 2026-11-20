import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/agent/agent_prompt.dart';
import 'package:towork/app/app_preferences_provider.dart';
import 'package:towork/app/reminder_wording.dart';
import 'package:towork/app/routes.dart';
import 'package:towork/domain/settings/app_preferences.dart';
import 'package:towork/l10n/strings.dart';
import 'package:towork/main.dart';
import 'package:towork/shell/quick_assist_app.dart';
import 'package:towork/shell/router.dart';

void main() {
  test('supported device preferences, Chinese variants and fallback', () {
    Locale resolve(List<Locale> locales) =>
        resolveAppLocale(locales, AppLocalizations.supportedLocales);
    expect(
      resolve([const Locale('fr'), const Locale('en', 'GB')]),
      const Locale('en'),
    );
    expect(resolve([const Locale('zh', 'TW')]), const Locale('zh'));
    expect(resolve([const Locale('de')]), const Locale('zh'));
    final legacy = const AppPreferences().toJson()..remove('language');
    expect(AppPreferences.fromJson(legacy, version: 1).language, 'system');
    expect(AgentPrompt.policy(replyLanguage: 'en'), contains('英语'));
    final digest = reminderWording('en');
    expect(digest.task, 'Task reminder');
    expect(
      digest.format(DateTime(2026, 11, 20), 1, 2, ['设置']),
      contains('1 due, 2 overdue. 设置.'),
    );
  });
  test('both catalogs define every message and its placeholders', () {
    Map<String, dynamic> read(String lang) =>
        jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
            as Map<String, dynamic>;
    final en = read('en'), zh = read('zh');
    final keys = en.keys.where((key) => !key.startsWith('@')).toSet();
    expect(keys, zh.keys.where((key) => !key.startsWith('@')).toSet());
    final argument = RegExp(r'\{(\w+)(?:\}|,)');
    for (final key in keys) {
      Set<String?> arguments(String message) =>
          argument.allMatches(message).map((m) => m[1]).toSet()..retainWhere(
            (name) => en['@$key']?['placeholders']?.containsKey(name) == true,
          );
      expect(
        arguments(en[key] as String),
        arguments(zh[key] as String),
        reason: key,
      );
    }
  });
  testWidgets(
    'appearance switches a live route and Quick Ask restores the same selection',
    (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      final container = ProviderContainer(
        overrides: [
          initialAppLocationProvider.overrideWithValue(AppRoutes.appearance),
        ],
      );
      Future<void> show(Widget widget) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: widget),
        );
        await tester.pumpAndSettle();
      }

      try {
        await show(const ToWorkApp());
        expect(find.text('Appearance'), findsOneWidget);
        await tester.tap(find.text('简体中文'));
        await tester.pumpAndSettle();
        expect(find.text('外观'), findsOneWidget);
        expect(container.read(appPreferencesSnapshotProvider).language, 'zh');
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        expect(find.text('Language'), findsOneWidget);
        expect(container.read(appPreferencesSnapshotProvider).language, 'en');
        tester.platformDispatcher.localesTestValue = const [Locale('zh', 'CN')];
        await tester.pumpAndSettle();
        expect(find.text('Appearance'), findsOneWidget);
        await show(
          QuickAssistApp(
            home: Builder(
              builder: (ctx) => Text(
                '${ctx.strings.addStep} / ${ctx.strings.tasks(1)} / ${ctx.strings.tasks(2)}',
              ),
            ),
          ),
        );
        expect(find.text('Add step / 1 task / 2 tasks'), findsOneWidget);
        expect(speechLocale, 'en-US');
        await container.read(appPreferencesControllerProvider).save({
          'language': 'system',
        });
        await tester.pumpAndSettle();
        expect(speechLocale, 'zh-CN');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }
    },
  );
}
