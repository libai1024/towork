import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/assist_provider.dart';
import '../../app/routes.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../../domain/assist/quick_assist.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/settings_shared.dart';

/// 设置行里的一句话摘要。系统不告知是否为默认助手时留空。
String quickAssistSummary(AssistEntryStatus? status) =>
    switch (status?.defaultAssistant) {
      true => '已设为默认助手',
      false => '未设为默认助手',
      null => '',
    };

/// 快捷唤醒：从别的应用上方打开「快问」面板的各个入口。
///
/// 这一页只做两件事：告诉用户有哪些入口，以及把需要去系统里完成的
/// 那一步（设为默认助手、固定到桌面）直接带过去。
class QuickAssistSettingsPage extends ConsumerStatefulWidget {
  const QuickAssistSettingsPage({super.key});

  @override
  ConsumerState<QuickAssistSettingsPage> createState() =>
      _QuickAssistSettingsPageState();
}

class _QuickAssistSettingsPageState
    extends ConsumerState<QuickAssistSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 用户从系统设置回来后，默认助手可能已经换了。
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(assistEntryStatusProvider);
    }
  }

  Future<void> _run(Future<bool> Function() action, String failure) async {
    final done = await action();
    if (mounted && !done) AppToast.show(context, message: failure);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final entries = ref.watch(assistEntriesProvider);
    final status = ref.watch(assistEntryStatusProvider).valueOrNull;
    final caption = AppTextStyles.caption.copyWith(color: c.labelSecondary);
    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            SettingsNavBar(
              title: '快捷唤醒',
              onBack: () => context.popOrGo(AppRoutes.settings),
              actions: [
                WorkspaceToolbarGroup(
                  children: [
                    WorkspaceToolbarAction(
                      key: const ValueKey('quick-assist-try'),
                      icon: LucideIcons.play,
                      label: '现在试一下',
                      onTap: () => _run(entries.openPanel, '这台设备上暂时打不开快问面板'),
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
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    children: [
                      const SettingsSectionTitle(label: '默认助手', topGap: 8),
                      SettingsGroupCard(
                        footer: Text(
                          '助手手势可唤起快问。电源键快捷操作由系统保留，第三方应用不能接管。',
                          style: caption,
                        ),
                        children: [
                          SettingsRow(
                            key: const ValueKey('quick-assist-default'),
                            icon: LucideIcons.sparkles,
                            title: '设为默认助手应用',
                            value: quickAssistSummary(status),
                            showChevron: true,
                            onTap: () => _run(
                              entries.openAssistantSettings,
                              '打不开系统设置，请到 系统设置 → 应用 → 默认应用 里选择 ToWork',
                            ),
                          ),
                        ],
                      ),
                      const SettingsSectionTitle(label: '其他入口'),
                      SettingsGroupCard(
                        children: [
                          if (status?.canPin ?? false)
                            SettingsRow(
                              key: const ValueKey('quick-assist-pin'),
                              icon: LucideIcons.squarePlus,
                              title: '添加「快问」到桌面',
                              showChevron: true,
                              onTap: () => _run(
                                entries.pinShortcut,
                                '桌面没有接受这次请求，可以长按 ToWork 图标，把「快问」拖到桌面',
                              ),
                            ),
                          if (status?.canPin ?? false)
                            SettingsRow(
                              key: const ValueKey('quick-assist-pin-voice'),
                              icon: LucideIcons.mic,
                              title: '添加「语音快问」到桌面',
                              showChevron: true,
                              onTap: () => _run(
                                () => entries.pinShortcut(voice: true),
                                '桌面没有接受这次请求，可以长按 ToWork 图标，把「语音快问」拖到桌面',
                              ),
                            ),
                          const _Entry(
                            icon: LucideIcons.zap,
                            title: '系统快捷功能',
                            detail: '在系统菜单中选「ToWork 快问」或「ToWork 语音快问」。',
                          ),
                          const _Entry(
                            icon: LucideIcons.fingerprint,
                            title: '华为智控键双触',
                            detail: '确认系统的添加提示后，到「智控键 / 双触」选择快问或语音快问。',
                          ),
                          const _Entry(
                            icon: LucideIcons.layoutGrid,
                            title: '控制中心',
                            detail: '编辑快捷开关，添加「快问」。',
                          ),
                          const _Entry(
                            icon: LucideIcons.textCursorInput,
                            title: '选中文字或分享',
                            detail: '选择「问 ToWork」。',
                          ),
                          const _Entry(
                            icon: LucideIcons.pointer,
                            title: '长按桌面图标',
                            detail: '选择「快问」或「语音快问」。',
                          ),
                        ],
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

/// 一个不需要在应用里操作的入口：告诉用户去哪里找到它。
class _Entry extends StatelessWidget {
  const _Entry({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      container: true,
      label: '$title：$detail',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 7,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 18, color: c.labelSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: AppTextStyles.footnote.copyWith(
                        color: c.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
