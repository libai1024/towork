import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/widgets/sheet_composer.dart';
import '../../../core/widgets/workspace_action_menu.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/models/models.dart';

/// 编辑/手动新增弹层结果（08-memory.md §5.4、§8.4：仅 content/type/expiresAt 可改）。
class MemoryDraft {
  const MemoryDraft({
    required this.content,
    required this.type,
    this.customTypeId,
    this.expiresAt,
  });

  final String content;
  final MemoryType type;
  final String? customTypeId;
  final DateTime? expiresAt;
}

/// 编辑（existing != null）或新增记忆（existing == null）底部 Sheet。
///
/// 演示模式不传 [onSave]，保存即弹出草稿由调用方同步落库；
/// 生产模式传入 [onSave]：弹层等待持久化结果，返回 false（保存失败）时
/// 保留弹层与已输入内容，返回 true 才关闭并回传草稿。
Future<MemoryDraft?> showMemoryEditSheet(
  BuildContext context, {
  MemoryEntry? existing,
  List<MemoryKind> kinds = MemoryKind.builtIn,
  String? initialKindId,
  Future<bool> Function(MemoryDraft draft)? onSave,
}) {
  return AppSheet.show<MemoryDraft>(
    context,
    child: _MemoryEditForm(
      existing: existing,
      kinds: kinds,
      initialKindId: initialKindId,
      onSave: onSave,
    ),
  );
}

class _MemoryEditForm extends StatefulWidget {
  const _MemoryEditForm({
    this.existing,
    required this.kinds,
    this.initialKindId,
    this.onSave,
  });

  final MemoryEntry? existing;
  final List<MemoryKind> kinds;
  final String? initialKindId;
  final Future<bool> Function(MemoryDraft draft)? onSave;

  @override
  State<_MemoryEditForm> createState() => _MemoryEditFormState();
}

class _MemoryEditFormState extends State<_MemoryEditForm> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.existing?.content ?? '',
  );
  late MemoryType _type = widget.existing?.type ?? MemoryType.fact;
  late String _kindId;
  late DateTime? _expiresAt = widget.existing?.expiresAt;
  bool _customExpiry = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customExpiry = _expiresAt != null;
    final requested = widget.existing?.typeScopeId ?? widget.initialKindId;
    _kindId = widget.kinds.any((kind) => kind.id == requested)
        ? requested!
        : _type.name;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt != null && _expiresAt!.isAfter(now)
          ? _expiresAt!
          : now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (mounted && picked != null) {
      setState(() {
        _customExpiry = true;
        _expiresAt = picked;
      });
    }
  }

  String get _expiryLabel {
    if (!_customExpiry || _expiresAt == null) return context.strings.longTerm;
    final d = _expiresAt!;
    return context.strings.expiresExpirylabel(
      d.year,
      d.month.toString().padLeft(2, '0'),
      d.day.toString().padLeft(2, '0'),
    );
  }

  MemoryDraft get _draft => MemoryDraft(
    content: _controller.text.trim(),
    type: _type,
    customTypeId: MemoryType.values.any((type) => type.name == _kindId)
        ? null
        : _kindId,
    expiresAt: _customExpiry ? _expiresAt : null,
  );

  Future<void> _submit() async {
    if (_saving || _controller.text.trim().isEmpty) return;
    final onSave = widget.onSave;
    if (onSave == null) {
      Navigator.pop(context, _draft);
      return;
    }
    setState(() => _saving = true);
    final saved = await onSave(_draft);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, _draft);
    } else {
      // 保存失败：弹层保留，已输入内容不动，等待用户修改后重试。
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kinds.where((kind) => kind.id == _kindId).firstOrNull;
    return SheetComposer(
      title: widget.existing == null
          ? context.strings.newMemory
          : context.strings.editMemory,
      hint: context.strings.memoryContent,
      controller: _controller,
      autofocus: widget.existing == null,
      multiline: true,
      maxLines: 6,
      action: context.strings.save,
      saving: _saving,
      onCommit: _submit,
      tools: [
        SheetChoice(
          icon: LucideIcons.tag,
          label: context.strings.memoryType,
          value: kind?.label ?? context.strings.type,
          onOpen: (anchor) async {
            final next = await showWorkspaceActionMenu<String>(
              anchor,
              selected: _kindId,
              items: [
                for (final k in widget.kinds)
                  (value: k.id, label: k.label, icon: LucideIcons.tag),
              ],
            );
            if (mounted && next != null) {
              final selected = widget.kinds.firstWhere((k) => k.id == next);
              setState(() {
                _kindId = next;
                _type = selected.semanticType ?? _type;
              });
            }
          },
        ),
        SheetChoice(
          icon: LucideIcons.calendar,
          label: context.strings.memoryRetention,
          value: _expiryLabel,
          onOpen: (anchor) async {
            final custom = await showWorkspaceActionMenu<bool>(
              anchor,
              selected: _customExpiry,
              items: [
                (
                  value: false,
                  label: context.strings.longTerm,
                  icon: LucideIcons.infinity,
                ),
                (
                  value: true,
                  label: context.strings.customDate,
                  icon: LucideIcons.calendar,
                ),
              ],
            );
            if (custom == null || !mounted) return;
            if (custom) {
              await _pickDate();
            } else {
              setState(() {
                _customExpiry = false;
                _expiresAt = null;
              });
            }
          },
        ),
      ],
    );
  }
}
