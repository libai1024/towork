import 'package:towork/app/app_preferences_provider.dart';
import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shell/router.dart';
import 'shell/app_frame.dart';
import 'shell/quick_assist_app.dart';
import 'shell/quick_assist_panel.dart';

import 'app/bootstrap.dart';
import 'app/free_workspace_bootstrap.dart';
import 'app/maintenance_registration_provider.dart';
import 'app/background_maintenance.dart';
import 'data/services/input_preferences_service.dart';
import 'data/update/code_update_gateway.dart';

import 'app/providers.dart';
import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeCodeUpdates();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final preferences = SharedInputPreferencesService();
  final startup = await loadInputPreference(preferences);
  final maintenance = await registerBackgroundMaintenance();
  if (startup.error != null) {
    debugPrint('Input preference unavailable: ${startup.error.runtimeType}');
  }
  runApp(
    ProviderScope(
      overrides: [
        maintenanceRegistrationProvider.overrideWith((ref) => maintenance),
      ],
      child: FreeWorkspaceBootstrap(
        legacyInputMode: startup.mode.name,
        child: const ToWorkApp(),
      ),
    ),
  );
}

/// 快捷面板的入口。Android 的 `AssistActivity` 用自己的引擎启动它，
/// 和主应用同处一个进程、共用同一个数据库文件。
@pragma('vm:entry-point')
Future<void> assistMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeCodeUpdates();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final startup = await loadInputPreference(SharedInputPreferencesService());
  runApp(
    ProviderScope(
      child: FreeWorkspaceBootstrap(
        legacyInputMode: startup.mode.name,
        placeholder: (context, retry) => QuickAssistApp(
          key: const ValueKey('quick-assist-startup'),
          home: QuickAssistStartup(retry: retry),
        ),
        child: const QuickAssistApp(),
      ),
    ),
  );
}

class ToWorkApp extends ConsumerWidget {
  const ToWorkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 外观设置（月之亮面/月之暗面/跟随系统）真实生效入口。
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'ToWork',
      debugShowCheckedModeBanner: false,
      locale: preferredLocale(
        ref.watch(appPreferencesSnapshotProvider.select((p) => p.language)),
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationDelegates,
      localeListResolutionCallback: resolveAppLocale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: AppMotion.tabSwitch,
      themeAnimationCurve: Curves.easeOut,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AppFrame(child: child),
    );
  }
}
