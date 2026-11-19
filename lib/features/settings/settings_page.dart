import '../../app/app_preferences_provider.dart';
import '../../app/assist_provider.dart';
import '../../app/backup_export.dart';
import '../../app/exports.dart';
import '../../app/model_settings_provider.dart';
import '../../app/routes.dart';
import '../../app/update/update_provider.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/app_avatar.dart';
import '../../app/workspace_state.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/membership/membership_badge.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/workspace_bottom_bar.dart';
import '../../app/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../core/ai/quota_widgets.dart';
import 'assistant_preferences_page.dart';
import 'quick_assist_settings_page.dart';
import 'widgets/settings_shared.dart';
import 'widgets/apple_privacy_rows.dart';
import 'widgets/speech_diagnostics_sheet.dart';
import '../../core/notifications/notification_diagnostics_sheet.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _exporting = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  /// 一键导出：先写临时文件并校验后原子发布，避免中断留下截断备份。
  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    File? temporary;
    try {
      final directory = await ref.read(exportsDirectoryProvider.future);
      final name =
          'towork_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$name');
      temporary = File('${file.path}.part');
      final payload = const JsonEncoder.withIndent('  ')
          .convert(_backupPayload());
      temporary.writeAsStringSync(payload, flush: true);
      final decoded = jsonDecode(temporary.readAsStringSync());
      if (decoded is! Map<String, Object?> || decoded['app'] != 'ToWork') {
        throw const FormatException('invalid export payload');
      }
      temporary.renameSync(file.path);
      temporary = null;
      await ref.read(appPreferencesControllerProvider).save({
        'last_export_at': DateTime.now().millisecondsSinceEpoch,
      });
      if (!mounted) return;
      AppToast.show(context, message: '已导出 $name');
    } catch (_) {
      if (temporary != null) {
        try {
          if (temporary.existsSync()) temporary.deleteSync();
        } catch (_) {}
      }
      if (mounted) AppToast.show(context, message: '导出失败，请重试');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Map<String, Object?> _backupPayload() => buildBackupPayload(
    todos: ref.read(todoListProvider),
    categories: ref.read(categoryListProvider),
    sessions: ref.read(sessionListProvider),
    memories: ref.read(memoryListProvider),
    reports: ref.read(reportListProvider),
    tables: ref.read(dataTableProvider).tables,
    dataRows: ref.read(dataTableProvider).rows.length,
  );

  /// 每日晨报时间滚轮（仅时:分），确认即生效 + Toast。
  void _pickMorningTime() {
    final c = AppColors.of(context);
    var (hour, minute) = ref.read(notifyMorningTimeProvider);
    var saving = false;
    AppSheet.show<void>(
      context,
      title: '每日晨报时间',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AbsorbPointer(
                absorbing: saving,
                child: SizedBox(
                  height: 160,
                  child: DefaultTextStyle(
                    style: AppTextStyles.title3.copyWith(color: c.labelPrimary),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: hour,
                            ),
                            itemExtent: 36,
                            backgroundColor: c.bgPrimary,
                            onSelectedItemChanged: (i) => hour = i,
                            children: [
                              for (var h = 0; h < 24; h++)
                                Center(
                                  child: Text(h.toString().padLeft(2, '0')),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          ':',
                          style: AppTextStyles.title3.copyWith(
                            color: c.labelTertiary,
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: minute,
                            ),
                            itemExtent: 36,
                            backgroundColor: c.bgPrimary,
                            onSelectedItemChanged: (i) => minute = i,
                            children: [
                              for (var m = 0; m < 60; m++)
                                Center(
                                  child: Text(m.toString().padLeft(2, '0')),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: AppButton(
                  label: '确定',
                  expand: true,
                  loading: saving,
                  onPressed: () async {
                    if (saving) return;
                    setSheetState(() => saving = true);
                    final saved = await savePreferences(context, ref, {
                      'morning_hour': hour,
                      'morning_minute': minute,
                    });
                    if (!context.mounted) return;
                    setSheetState(() => saving = false);
                    if (!saved) return;
                    Navigator.of(context).pop();
                    AppToast.show(
                      context,
                      message:
                          '晨报改到 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleMemoryFreeze(bool value) async {
    final saved = await savePreferences(context, ref, {'memory_paused': value});
    if (!mounted || !saved) return;
    if (value) {
      AppToast.show(context, message: '好的，这段时间我不会记东西');
    }
  }

  // -------------------------------------------------------------------------
  // 构建
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final writePermission = ref.watch(aiWritePermissionProvider);
    final memoryPaused = ref.watch(memoryPausedProvider);
    final notifyDue = ref.watch(notifyDueEnabledProvider);
    final notifyMorning = ref.watch(notifyMorningEnabledProvider);
    final (morningH, morningM) = ref.watch(notifyMorningTimeProvider);
    final notifyReport = ref.watch(notifyReportEnabledProvider);
    final lastExportAt = ref.watch(
      appPreferencesSnapshotProvider.select((p) => p.lastExportAt),
    );
    final fontScale = ref.watch(fontScaleProvider);
    final version = ref.watch(appVersionProvider);
    final assistEntries = ref.watch(assistEntryStatusProvider).valueOrNull;
    final activeAccount = ref.watch(liveModelAccountsProvider)?.active;
    final modelSummary = activeAccount == null
        ? '添加 Key'
        : '${activeAccount.descriptor.shortLabel} '
              '${accountStatusLabel(activeAccount, DateTime.now().toUtc())}';

    final themeLabel = switch (themeMode) {
      ThemeMode.light => '浅色',
      ThemeMode.dark => '深色',
      ThemeMode.system => '跟随系统',
    };
    final morningTime =
        '${morningH.toString().padLeft(2, '0')}:${morningM.toString().padLeft(2, '0')}';

    final sections = <Widget>[
      const SettingsSectionTitle(label: '账号', topGap: 8),
      SettingsGroupCard(
        flat: true,
        dividerIndent: 68,
        children: [
          SettingsRow(
            compact: true,
            leading: AppAvatar(nickname: user.nickname, size: 30),
            title: user.nickname,
            titleWeight: FontWeight.w500,
            showChevron: true,
            semanticLabel: '账号详情',
            onTap: () => context.push(AppRoutes.localProfile),
            trailing: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: MembershipBadge(
                tier: user.tier,
                onTap: () => context.push(AppRoutes.membership),
              ),
            ),
          ),
        ],
      ),
      const SettingsSectionTitle(label: 'AI'),
      SettingsGroupCard(
        flat: true,
        children: [
          SettingsRow(
            compact: true,
            icon: LucideIcons.sparkles,
            title: '模型与额度',
            value: modelSummary,
            showChevron: true,
            onTap: () => context.push(AppRoutes.modelAccounts),
          ),
          SettingsRow(
            compact: true,
            icon: LucideIcons.slidersHorizontal,
            title: '助手偏好',
            value: assistantPreferencesSummary(
              ref.watch(appPreferencesSnapshotProvider),
            ),
            showChevron: true,
            onTap: () => context.push(AppRoutes.assistantPreferences),
          ),
        ],
      ),
      const SettingsSectionTitle(label: '隐私与权限'),
      SettingsGroupCard(
        flat: true,
        children: [
          ...applePrivacyRows(context),
          SettingsRow(
            compact: true,
            icon: LucideIcons.penLine,
            title: 'AI 写入权限',
            value: writePermission.label,
            valueColor: c.labelSecondary,
            showChevron: true,
            onTap: () => showAiWritePermissionSheet(context, ref),
          ),
          SettingsSwitchRow(
            compact: true,
            icon: LucideIcons.shieldOff,
            title: '免记忆模式',
            value: memoryPaused,
            onChanged: _toggleMemoryFreeze,
          ),
        ],
      ),
      const SettingsSectionTitle(label: '输入与唤醒'),
      SettingsGroupCard(
        flat: true,
        children: [
          if (assistEntries?.supported ?? false)
            SettingsRow(
              compact: true,
              icon: LucideIcons.zap,
              title: '快捷唤醒',
              value: quickAssistSummary(assistEntries),
              showChevron: true,
              onTap: () => context.push(AppRoutes.quickAssist),
            ),
          SettingsRow(
            compact: true,
            icon: LucideIcons.audioLines,
            title: '语音识别检测',
            showChevron: true,
            onTap: () => AppSheet.show<void>(
              context,
              title: '语音识别检测',
              child: const SpeechDiagnosticsSheet(),
            ),
          ),
          SettingsRow(
            compact: true,
            icon: LucideIcons.mic,
            title: '默认输入方式',
            value: ref.watch(defaultInputModeProvider) == ChatInputMode.voice
                ? '语音'
                : '键盘',
            showChevron: true,
            onTap: () {
              // 与「AI 写入权限」同一套 Sheet 选项行语法（09 §3）。
              final current = ref.read(defaultInputModeProvider);
              AppSheet.show<void>(
                context,
                title: '默认输入方式',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in ChatInputMode.values)
                      SheetOptionRow(
                        icon: mode == ChatInputMode.voice
                            ? LucideIcons.mic
                            : LucideIcons.keyboard,
                        title: mode == ChatInputMode.voice ? '语音' : '键盘',
                        selected: mode == current,
                        onTap: () async {
                          Navigator.of(context).pop();
                          try {
                            await ref
                                .read(defaultInputModeProvider.notifier)
                                .select(mode);
                          } catch (_) {
                            if (context.mounted) {
                              AppToast.show(context, message: '未能保存，请重试');
                            }
                          }
                        },
                      ),
                    const SizedBox(height: 6),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      const SettingsSectionTitle(label: '通知'),
      SettingsGroupCard(
        flat: true,
        children: [
          SettingsSwitchRow(
            compact: true,
            icon: LucideIcons.alarmClock,
            title: '截止提醒',
            value: notifyDue,
            onChanged: (v) => savePreferences(context, ref, {'notify_due': v}),
          ),
          // 行点按 = 打开时间选择/开启，与开关切换是两个不同操作，
          // 保持复合语义但开关播报名区分开，避免与行按钮完全重复。
          SettingsRow(
            compact: true,
            icon: LucideIcons.sunrise,
            title: '每日晨报',
            value: notifyMorning ? morningTime : '已关闭',
            showChevron: notifyMorning,
            onTap: notifyMorning
                ? _pickMorningTime
                : () => savePreferences(context, ref, {'notify_morning': true}),
            trailing: SettingsSwitch(
              value: notifyMorning,
              onChanged: (v) =>
                  savePreferences(context, ref, {'notify_morning': v}),
              semanticLabel: '每日晨报开关',
            ),
          ),
          SettingsSwitchRow(
            compact: true,
            icon: LucideIcons.fileText,
            title: '报告就绪提醒',
            value: notifyReport,
            onChanged: (v) =>
                savePreferences(context, ref, {'notify_report': v}),
          ),
          SettingsRow(
            compact: true,
            icon: LucideIcons.circleHelp,
            title: '通知与提醒设置',
            showChevron: true,
            onTap: () => showNotificationDiagnostics(context),
          ),
        ],
      ),
      const SettingsSectionTitle(label: '外观'),
      SettingsGroupCard(
        flat: true,
        dividerIndent: 16,
        children: [
          SettingsRow(
            compact: true,
            leading: Icon(
              themeMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.sun,
              size: 20,
              color: c.labelSecondary,
            ),
            title: '主题',
            value: themeLabel,
            showChevron: true,
            onTap: () => context.push(AppRoutes.appearance),
          ),
          SettingsRow(
            compact: true,
            icon: LucideIcons.type,
            title: '字号',
            value: fontScale <= 0.9 ? '小' : (fontScale >= 1.15 ? '大' : '标准'),
            showChevron: true,
            onTap: () => context.push(AppRoutes.appearance),
          ),
        ],
      ),
      const SettingsSectionTitle(label: '数据备份'),
      SettingsGroupCard(
        flat: true,
        children: [
          SettingsRow(
            compact: true,
            icon: LucideIcons.download,
            title: '一键导出',
            showChevron: !_exporting,
            onTap: _exporting ? null : _export,
            trailing: _exporting
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.brand,
                      ),
                    ),
                  )
                : null,
          ),
          SettingsRow(
            compact: true,
            icon: LucideIcons.history,
            title: '上次导出',
            value: _exportLabel(lastExportAt),
          ),
        ],
      ),
      const SettingsSectionTitle(label: '关于'),
      SettingsGroupCard(
        flat: true,
        children: [
          SettingsRow(
            compact: true,
            icon: LucideIcons.info,
            title:
                ref.watch(installedAppProvider).valueOrNull?.canUpdate == true
                ? '检查更新'
                : '版本',
            value: version,
            showChevron:
                ref.watch(installedAppProvider).valueOrNull?.canUpdate == true,
            onTap:
                ref.watch(installedAppProvider).valueOrNull?.canUpdate == true
                ? () => context.push(AppRoutes.update)
                : null,
          ),
          SettingsRow(
            compact: true,
            icon: LucideIcons.scale,
            title: '开源许可',
            showChevron: true,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'ToWork',
              applicationVersion: version,
            ),
          ),
        ],
      ),
    ];
    final visible = _filteredSections(sections);

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            WorkspaceNavBar(title: '设置', onBack: _back),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (visible.isEmpty)
                      const AppEmptyState(
                        icon: LucideIcons.search,
                        title: '没有找到相关设置',
                      )
                    else
                      ListView(
                        key: const ValueKey('settings-list'),
                        padding: const EdgeInsets.only(bottom: 80),
                        children: visible,
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: WorkspaceBottomBar(
                        searchController: _searchController,
                        hint: '搜索设置',
                        onSearchChanged: (_) => setState(() {}),
                        onClear: () => setState(_searchController.clear),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Keep actions and controls intact while filtering the existing sections.
  List<Widget> _filteredSections(List<Widget> sections) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return sections;
    final matches = <Widget>[];
    for (var i = 0; i + 1 < sections.length; i += 2) {
      final title = sections[i] as SettingsSectionTitle;
      final group = sections[i + 1] as SettingsGroupCard;
      final entireGroup = title.label.toLowerCase().contains(query);
      final rows = group.children.where((child) {
        if (entireGroup) return true;
        final searchable = switch (child) {
          SettingsRow(:final title, :final value, :final semanticLabel) =>
            '$title ${value ?? ''} ${semanticLabel ?? ''}',
          SettingsSwitchRow(:final title) => title,
          _ => null,
        };
        return searchable?.toLowerCase().contains(query) ?? false;
      }).toList();
      if (rows.isEmpty) continue;
      matches.addAll([
        title,
        SettingsGroupCard(
          flat: true,
          dividerIndent: group.dividerIndent,
          children: rows,
        ),
      ]);
    }
    return matches;
  }

  String _exportLabel(int millis) {
    if (millis <= 0) return '尚未导出';
    final t = DateTime.fromMillisecondsSinceEpoch(millis);
    final hm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final day = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return '今天 $hm';
    if (day == today.subtract(const Duration(days: 1))) return '昨天 $hm';
    return '${t.month}月${t.day}日 $hm';
  }
}
