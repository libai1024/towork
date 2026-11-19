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
      UpdatePhase.idle || UpdatePhase.checking => '正在检查更新',
      UpdatePhase.current => '已是最新版本',
      UpdatePhase.available => '发现新版本',
      UpdatePhase.downloading => '正在下载更新',
      UpdatePhase.verifying => state.isCode ? '正在验证补丁' : '正在校验安装包',
      UpdatePhase.applying => '正在合成安装包',
      UpdatePhase.ready => state.isCode ? '补丁已就绪' : '安装包已就绪',
      UpdatePhase.permission => '需要安装应用权限',
      UpdatePhase.installing => '请在系统界面确认安装',
      UpdatePhase.restarting => '正在重启并加载更新',
      UpdatePhase.failed => '检查更新失败',
      UpdatePhase.unsupported => '此平台暂未提供应用内安装',
    };
    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(
              title: '检查更新',
              onBack: () => context.popOrGo(AppRoutes.settings),
              actions: [
                if (!state.busy &&
                    !state.codeReady &&
                    state.phase != UpdatePhase.unsupported)
                  WorkspaceToolbarGroup(
                    children: [
                      WorkspaceToolbarAction(
                        icon: LucideIcons.rotateCw,
                        label: '重新检查',
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
                                  '${state.installed?.label ?? '读取中'}${state.codeStatus.activeVersion == null ? '' : ' P${state.codeStatus.activeVersion}'}',
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
                          '${release.versionName} (${release.versionCode}) ${state.isDelta ? '差量更新' : '完整安装包'} ${_mb(state.downloadSize)} MB',
                          style: AppTextStyles.body.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ],
                      if (codeUpdate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${codeUpdate.label}${codeUpdate.withdrawal ? '' : ' ${_mb(codeUpdate.size)} MB'}',
                          style: AppTextStyles.body.copyWith(
                            color: c.labelSecondary,
                          ),
                        ),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('本次更新', style: AppTextStyles.subhead),
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
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('差量更新未完成，已切换完整安装包。'),
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
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('允许此来源后返回安装。'),
                        ),
                      const SizedBox(height: 12),
                      if (state.phase == UpdatePhase.available)
                        AppButton(
                          label: state.isCode
                              ? (codeUpdate!.withdrawal ? '恢复并重启' : '更新并重启')
                              : '下载更新',
                          onPressed: controller.download,
                          expand: true,
                        ),
                      if (downloading ||
                          (state.phase == UpdatePhase.verifying &&
                              !state.isCode) ||
                          state.phase == UpdatePhase.applying)
                        AppButton(
                          label: state.isCode
                              ? '取消下载'
                              : state.phase == UpdatePhase.applying
                              ? '取消更新'
                              : '暂停下载',
                          onPressed: controller.cancelDownload,
                          type: AppButtonType.secondary,
                          expand: true,
                        ),
                      if (state.phase == UpdatePhase.ready ||
                          state.phase == UpdatePhase.permission)
                        AppButton(
                          label: state.isCode ? '立即重启' : '安装并重新打开',
                          onPressed: controller.install,
                          expand: true,
                        ),
                      if (state.phase == UpdatePhase.installing)
                        AppButton(
                          label: '重新打开安装',
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
