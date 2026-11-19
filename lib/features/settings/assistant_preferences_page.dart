import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/app_preferences_provider.dart';
import '../../app/routes.dart';
import '../../core/widgets/workspace_nav_bar.dart';
import '../../core/widgets/app_field_label.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/app_toast.dart';
import '../../domain/settings/app_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/settings_shared.dart';

/// 设置行里的一句话摘要。
String assistantPreferencesSummary(AppPreferences preferences) {
  final parts = [
    if (preferences.customInstructions.trim().isNotEmpty) '已写说明',
    if (preferences.speechVocabulary.isNotEmpty)
      '${preferences.speechVocabulary.length} 个常用词',
  ];
  return parts.isEmpty ? '未设置' : parts.join(' ');
}

/// 助手偏好：写给助手的长期说明与常用词。
///
/// 两者都随每轮对话带给模型（见 `AgentPrompt.turn`）：说明是偏好，不能覆盖
/// 写入权限等规则；常用词帮助纠正语音转写里读音相近的专有名词。
class AssistantPreferencesPage extends ConsumerStatefulWidget {
  const AssistantPreferencesPage({super.key});

  @override
  ConsumerState<AssistantPreferencesPage> createState() =>
      _AssistantPreferencesPageState();
}

class _AssistantPreferencesPageState
    extends ConsumerState<AssistantPreferencesPage> {
  late final TextEditingController _instructions;
  final _word = TextEditingController();
  final _wordFocus = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _instructions = TextEditingController(
      text: ref.read(appPreferencesSnapshotProvider).customInstructions,
    );
  }

  @override
  void dispose() {
    _instructions.dispose();
    _word.dispose();
    _wordFocus.dispose();
    super.dispose();
  }

  Future<void> _saveInstructions() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    final text = _instructions.text.trim();
    final saved = await savePreferences(context, ref, {
      'custom_instructions': text,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) {
      _instructions.text = text;
      AppToast.show(context, message: '已保存，下一次对话起生效');
    }
  }

  Future<void> _addWord() async {
    final word = _word.text.trim();
    final words = ref.read(appPreferencesSnapshotProvider).speechVocabulary;
    final String? problem;
    if (word.isEmpty) {
      problem = null;
    } else if (word.length > AppPreferences.maxVocabularyLength) {
      problem = '每个词最多 ${AppPreferences.maxVocabularyLength} 个字符';
    } else if (words.any((w) => w.toLowerCase() == word.toLowerCase())) {
      problem = '「$word」已经在列表里';
    } else if (words.length >= AppPreferences.maxVocabulary) {
      problem = '最多 ${AppPreferences.maxVocabulary} 个常用词，请先删除不用的';
    } else {
      problem = null;
    }
    if (word.isEmpty) return;
    if (problem != null) {
      AppToast.show(context, message: problem);
      return;
    }
    final saved = await savePreferences(context, ref, {
      'speech_vocabulary': [...words, word],
    });
    if (!mounted || !saved) return;
    _word.clear();
    _wordFocus.requestFocus();
  }

  Future<void> _removeWord(String word) => savePreferences(context, ref, {
    'speech_vocabulary': [
      for (final item
          in ref.read(appPreferencesSnapshotProvider).speechVocabulary)
        if (item != word) item,
    ],
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final preferences = ref.watch(appPreferencesSnapshotProvider);
    final words = preferences.speechVocabulary;
    final changed = _instructions.text.trim() != preferences.customInstructions;
    final caption = AppTextStyles.caption.copyWith(color: c.labelSecondary);

    return Scaffold(
      backgroundColor: c.bgGround,
      body: SafeArea(
        child: Column(
          children: [
            SettingsNavBar(
              title: '助手偏好',
              onBack: () => context.popOrGo(AppRoutes.settings),
              actions: [
                WorkspaceToolbarGroup(
                  children: [
                    WorkspaceToolbarAction(
                      key: const ValueKey('save-assistant-instructions'),
                      label: '保存说明',
                      icon: LucideIcons.check,
                      onTap: changed && !_saving ? _saveInstructions : null,
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      4,
                      AppSpacing.pageHorizontal,
                      16,
                    ),
                    children: [
                      AppFieldLabel(
                        label: '长期说明',
                        child: TextField(
                          key: const ValueKey('assistant-instructions'),
                          controller: _instructions,
                          enabled: !_saving,
                          minLines: 2,
                          maxLines: 10,
                          maxLength: AppPreferences.maxInstructionLength,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: '例如：回复用简体中文',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: AppFieldLabel(
                              label: '常用词',
                              child: TextField(
                                key: const ValueKey('assistant-word-input'),
                                controller: _word,
                                focusNode: _wordFocus,
                                maxLength: AppPreferences.maxVocabularyLength,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: '人名、项目名或产品名',
                                ),
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _addWord(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          WorkspaceToolbarAction(
                            key: const ValueKey('assistant-word-add'),
                            label: '添加',
                            icon: LucideIcons.plus,
                            onTap: _word.text.trim().isEmpty ? null : _addWord,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '语音词库 ${words.length}/${AppPreferences.maxVocabulary}',
                        style: caption,
                      ),
                      if (words.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final word in words)
                                _WordChip(
                                  key: ValueKey('assistant-word-$word'),
                                  word: word,
                                  onRemove: () => _removeWord(word),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      Text(
                        '发送给模型的内容',
                        style: AppTextStyles.body.copyWith(
                          color: c.labelPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '每轮发送时间、称呼、长期说明和常用词。开启 Agent 后，另附分类及最多 12 条进行中待办的标题和截止时间。',
                        style: caption,
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

class _WordChip extends StatelessWidget {
  const _WordChip({super.key, required this.word, required this.onRemove});

  final String word;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: ShapeDecoration(color: c.fill1, shape: const StadiumBorder()),
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.footnote.copyWith(color: c.labelPrimary),
            ),
          ),
          AppPressable(
            onTap: onRemove,
            semanticLabel: '删除常用词 $word',
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(LucideIcons.x, size: 14, color: c.labelSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
