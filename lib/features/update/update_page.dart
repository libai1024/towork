import 'package:towork/l10n/strings.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../app/update/update_controller.dart';
import '../../app/update/update_provider.dart';
import '../../app/update/release_history_provider.dart';
import '../../domain/update/release_history.dart';
import 'release_history_view.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/work_mark.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/workspace_nav_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class UpdatePage extends ConsumerStatefulWidget {
  const UpdatePage({super.key});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      final controller = ref.read(updateControllerProvider.notifier);
      final phase = ref.read(updateControllerProvider).phase;
      if (phase == UpdatePhase.idle ||
          phase == UpdatePhase.current ||
          phase == UpdatePhase.failed) {
        unawaited(controller.check());
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_active) {
        unawaited(
          ref.read(updateControllerProvider.notifier).pollInstallation(),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final c = AppColors.of(context);
    final release = state.release;
    final codeUpdate = state.codeUpdate;
    final history =
        ref.watch(releaseHistoryProvider).valueOrNull ??
        const <ReleaseHistoryEntry>[];
    final installed = state.installed;
    final currentId =
        '${installed?.versionCode}/${state.codeStatus.activeVersion ?? '0'}';
    final offeredId = release != null
        ? '${release.versionCode}/0'
        : codeUpdate == null || codeUpdate.withdrawal
        ? null
        : '${installed?.versionCode}/${codeUpdate.version}';
    final offered = history.where((entry) => entry.id == offeredId).firstOrNull;
    final notes = release != null && release.notes.isNotEmpty
        ? release.notes
        : offered?.notes ?? const <String>[];
    final downloading = state.phase == UpdatePhase.downloading;
    final status = switch (state.phase) {
      UpdatePhase.idle ||
      UpdatePhase.checking => context.strings.checkingForUpdates,
      UpdatePhase.current => context.strings.upToDate,
      UpdatePhase.available => context.strings.updateAvailable,
      UpdatePhase.downloading => context.strings.downloadingUpdate,
      UpdatePhase.verifying =>
        state.isCode
            ? context.strings.verifyingPatch
            : context.strings.verifyingInstaller,
      UpdatePhase.applying => context.strings.buildingInstaller,
      UpdatePhase.ready =>
        state.isCode
            ? context.strings.patchReady
            : context.strings.installerReady,
      UpdatePhase.permission => context.strings.permissionToInstallAppsRequired,
      UpdatePhase.installing =>
        context.strings.confirmInstallationInTheSystemDialog,
      UpdatePhase.restarting => context.strings.restartingToApplyUpdate,
      UpdatePhase.failed => context.strings.updateCheckFailed,
      UpdatePhase.unsupported =>
        context.strings.inAppInstallationUnavailableOnThisPlatform,
    };
    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(
              title: context.strings.checkForUpdates,
              onBack: () => context.popOrGo(AppRoutes.settings),
              actions: [
                if (!state.busy &&
                    !state.codeReady &&
                    state.phase != UpdatePhase.unsupported)
                  WorkspaceToolbarGroup(
                    children: [
                      WorkspaceToolbarAction(
                        icon: LucideIcons.rotateCw,
                        label: context.strings.checkAgainBuild,
                        onTap: () {
                          ref.invalidate(releaseHistoryProvider);
                          controller.check();
                        },
                      ),
                    ],
                  ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      Row(
                        children: [
                          const ExcludeSemantics(child: WorkMark(size: 38)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ToWork',
                                  style: AppTextStyles.title3.copyWith(
                                    color: c.labelPrimary,
                                  ),
                                ),
                                Text(
                                  '${state.installed == null
                                      ? context.strings.loading
                                      : state.installed!.versionName.isEmpty
                                      ? context.strings.unknownVersion
                                      : state.installed!.label}${state.codeStatus.activeVersion == null ? '' : ' P${state.codeStatus.activeVersion}'}',
                                  style: AppTextStyles.footnote.copyWith(
                                    color: c.labelSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: c.separator),
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          status,
                          style: AppTextStyles.subhead.copyWith(
                            color: c.labelPrimary,
                          ),
                        ),
                      ),
                      if (release != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${release.versionName} (${release.versionCode}) ${state.isDelta ? context.strings.deltaUpdate : context.strings.fullInstaller} ${_mb(state.downloadSize)} MB',
                          style: AppTextStyles.body.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ],
                      if (codeUpdate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${codeUpdate.withdrawal ? context.strings.restoreBaseVersion : context.strings.patchP(codeUpdate.version)}${codeUpdate.withdrawal ? '' : ' ${_mb(codeUpdate.size)} MB'}',
                          style: AppTextStyles.body.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          context.strings.whatsNew,
                          style: AppTextStyles.subhead,
                        ),
                        ReleaseNotes(notes: notes),
                      ],
                      if (state.phase == UpdatePhase.checking ||
                          state.phase == UpdatePhase.verifying ||
                          state.phase == UpdatePhase.applying ||
                          state.phase == UpdatePhase.restarting ||
                          downloading) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: downloading && state.downloadSize > 0
                              ? (state.received / state.downloadSize).clamp(
                                  0.0,
                                  1.0,
                                )
                              : null,
                        ),
                        if (downloading && state.downloadSize > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${_mb(state.received)} / ${_mb(state.downloadSize)} MB',
                            ),
                          ),
                      ],
                      if (state.fullDownload && release?.patch != null)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            context
                                .strings
                                .deltaUpdateIncompleteSwitchedToTheFull,
                          ),
                        ),
                      if (state.message case final message?)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              message,
                              style: AppTextStyles.body.copyWith(
                                color: c.labelSecondary,
                              ),
                            ),
                          ),
                        ),
                      if (state.phase == UpdatePhase.permission)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            context.strings.allowThisSourceThenReturnToInstall,
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (state.phase == UpdatePhase.available)
                        AppButton(
                          label: state.isCode
                              ? (codeUpdate!.withdrawal
                                    ? context.strings.restoreAndRestart
                                    : context.strings.updateAndRestart)
                              : context.strings.downloadUpdate,
                          onPressed: controller.download,
                          expand: true,
                        ),
                      if (downloading ||
                          (state.phase == UpdatePhase.verifying &&
                              !state.isCode) ||
                          state.phase == UpdatePhase.applying)
                        AppButton(
                          label: state.isCode
                              ? context.strings.cancelDownload
                              : state.phase == UpdatePhase.applying
                              ? context.strings.cancelUpdate
                              : context.strings.pauseDownload,
                          onPressed: controller.cancelDownload,
                          type: AppButtonType.secondary,
                          expand: true,
                        ),
                      if (state.phase == UpdatePhase.ready ||
                          state.phase == UpdatePhase.permission)
                        AppButton(
                          label: state.isCode
                              ? context.strings.restartNow
                              : context.strings.installAndReopen,
                          onPressed: controller.install,
                          expand: true,
                        ),
                      if (state.phase == UpdatePhase.installing)
                        AppButton(
                          label: context.strings.reopenInstaller,
                          onPressed: controller.install,
                          type: AppButtonType.secondary,
                          expand: true,
                        ),
                      if (history.isNotEmpty && installed != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 16),
                          child: ReleaseHistoryView(
                            entries: history,
                            currentId: currentId,
                            offeredId: offeredId,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _mb(int bytes) => (bytes / 1024 / 1024).toStringAsFixed(1);
