import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'model_action_button.dart';

class SettingsEditorHeader extends StatefulWidget {
  const SettingsEditorHeader({
    super.key,
    required this.title,
    required this.onClose,
    required this.onSave,
    required this.saving,
    required this.saveKey,
    required this.saveLabel,
    this.handleKey,
  });
  final String title;
  final VoidCallback onClose;
  final VoidCallback? onSave;
  final bool saving;
  final Key saveKey;
  final Key? handleKey;
  final String saveLabel;
  @override
  State<SettingsEditorHeader> createState() => _SettingsEditorHeaderState();
}

class _SettingsEditorHeaderState extends State<SettingsEditorHeader> {
  double _drag = 0;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      key: widget.handleKey,
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _drag = 0,
      onVerticalDragUpdate: (details) => _drag += details.delta.dy,
      onVerticalDragEnd: (details) {
        if (_drag >= 48 ||
            (_drag > 0 && (details.primaryVelocity ?? 0) > 600)) {
          widget.onClose();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: c.fill3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                ModelActionButton(
                  label: context.strings.close,
                  icon: LucideIcons.x,
                  onPressed: widget.onClose,
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.title3.copyWith(color: c.labelPrimary),
                  ),
                ),
                ModelActionButton(
                  key: widget.saveKey,
                  label: widget.saveLabel,
                  icon: LucideIcons.check,
                  primary: true,
                  loading: widget.saving,
                  onPressed: widget.onSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
