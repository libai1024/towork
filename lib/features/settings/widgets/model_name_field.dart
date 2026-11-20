import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_sheet.dart';
import '../../../core/ai/model_identity.dart';
import '../../../domain/ai/model_gateway.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'model_directory_sheet.dart';
import 'model_action_button.dart';
import 'settings_input_field.dart';
import 'settings_shared.dart';

class ModelNameField extends StatefulWidget {
  const ModelNameField({
    super.key,
    required this.descriptor,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.load,
    required this.credentialsRevision,
  });
  final ProviderDescriptor descriptor;
  final TextEditingController controller;
  final bool enabled;
  final int credentialsRevision;
  final Future<List<String>> Function(ModelCancellation)? load;
  final VoidCallback onChanged;
  @override
  State<ModelNameField> createState() => _ModelNameFieldState();
}

class _ModelNameFieldState extends State<ModelNameField> {
  late bool _custom = widget.descriptor.preset(widget.controller.text) == null;

  List<String>? _cached;
  @override
  void didUpdateWidget(ModelNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.credentialsRevision != widget.credentialsRevision) {
      _cached = null;
    }
  }

  Future<void> _browse() async {
    final load = widget.load;
    if (load == null) return;
    final revision = widget.credentialsRevision;
    final choice = await AppSheet.show<String>(
      context,
      title: context.strings.availableModels,
      child: ModelDirectorySheet(
        product: widget.descriptor.kind,
        load: load,
        cached: _cached,
        current: widget.controller.text,
        onLoaded: (items) {
          if (mounted && revision == widget.credentialsRevision) {
            setState(() => _cached = items);
          }
        },
      ),
    );
    if (!mounted || choice == null || revision != widget.credentialsRevision) {
      return;
    }
    setState(() => _custom = widget.descriptor.preset(choice) == null);
    if (widget.controller.text == choice) return;
    widget.controller.text = choice;
    widget.onChanged();
  }

  Future<void> _choose() async {
    final choice = await AppSheet.show<String>(
      context,
      title: context.strings.chooseModel,
      child: Builder(
        builder: (sheet) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final preset in widget.descriptor.models)
                SheetOptionRow(
                  title: preset.label,
                  leading: ProviderLogo(widget.descriptor.kind),
                  selected: !_custom && preset.id == widget.controller.text,
                  onTap: () => Navigator.of(sheet).pop(preset.id),
                ),
              SheetOptionRow(
                title: context.strings.customModel,
                selected: _custom,
                onTap: () => Navigator.of(sheet).pop(''),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null || !widget.enabled) return;
    if (choice.isEmpty) {
      if (!_custom) setState(() => _custom = true);
      return;
    }
    setState(() => _custom = false);
    if (widget.controller.text == choice) return;
    widget.controller.text = choice;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.descriptor.models.isNotEmpty)
              SettingsRow(
                key: const ValueKey('choose-account-model'),
                title: context.strings.model,
                valueLeading: _custom
                    ? null
                    : ProviderLogo(widget.descriptor.kind, size: 14),
                value: _custom
                    ? context.strings.customModel
                    : widget.descriptor.preset(widget.controller.text)?.label,
                showChevron: true,
                enabled: widget.enabled,
                onTap: _choose,
              ),
            if (_custom || widget.descriptor.models.isEmpty)
              SettingsInputField(
                fieldKey: const ValueKey('model-name-input'),
                prefix: ProviderLogo(widget.descriptor.kind, size: 14),
                label: context.strings.modelId,
                hint: context.strings.enterModelId,
                controller: widget.controller,
                enabled: widget.enabled,
                maxLength: 120,
                onChanged: (_) => widget.onChanged(),
              ),
          ],
        ),
      ),
      ModelActionButton(
        key: const ValueKey('model-fetch'),
        label: _cached == null
            ? context.strings.fetchModelList
            : context.strings.selectAFetchedModel,
        icon: _cached == null ? LucideIcons.download : LucideIcons.listChecks,
        onPressed: widget.load == null ? null : _browse,
      ),
    ],
  );
}
