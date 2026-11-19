import 'package:flutter/material.dart';

import '../../../core/widgets/app_inline_input.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Keep the field name next to the value, including while editing.
class SettingsInputField extends StatefulWidget {
  const SettingsInputField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.onSubmitted,
    this.secret = false,
    this.prefix,
    this.keyboardType,
    this.maxLength,
  });

  final Key fieldKey;
  final Widget? prefix;
  final String label, hint;
  final TextEditingController controller;
  final bool enabled, secret;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final int? maxLength;

  @override
  State<SettingsInputField> createState() => _SettingsInputFieldState();
}

class _SettingsInputFieldState extends State<SettingsInputField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Focus(
      canRequestFocus: false,
      onFocusChange: (_) => setState(() {}),
      child: GestureDetector(
        onTap: widget.enabled ? _focus.requestFocus : null,
        excludeFromSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: c.bgPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focus.hasFocus ? c.labelSecondary : c.separator,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final label = ExcludeSemantics(
                child: Text(
                  widget.label,
                  style: AppTextStyles.body.copyWith(color: c.labelSecondary),
                ),
              );
              final compact =
                  bounds.maxWidth < 170 ||
                  MediaQuery.textScalerOf(context).scale(14) >= 23;
              final editor = Semantics(
                label: widget.label,
                child: TextField(
                  key: widget.fieldKey,
                  focusNode: _focus,
                  textAlign: compact || _focus.hasFocus
                      ? TextAlign.start
                      : TextAlign.end,
                  controller: widget.controller,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.secret,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: !widget.secret,
                  maxLength: widget.maxLength,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => null,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: AppTextStyles.body.copyWith(color: c.labelPrimary),
                  decoration:
                      appInlineInput(
                        hintText: widget.hint,
                        hintStyle: AppTextStyles.body.copyWith(
                          color: c.labelTertiary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 3),
                      ).copyWith(
                        prefixIcon: widget.prefix,
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 24,
                        ),
                      ),
                ),
              );
              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [label, editor],
                );
              }
              return Row(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: bounds.maxWidth * .38,
                    ),
                    child: label,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: editor),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
