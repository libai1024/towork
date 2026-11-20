import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/sheet_composer.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../domain/models/memory.dart';

Future<String?> showMemoryTypeSheet(
  BuildContext context,
  List<MemoryKind> kinds,
) => AppSheet.show<String>(context, child: _TypeForm(kinds: kinds));

class _TypeForm extends StatefulWidget {
  const _TypeForm({required this.kinds});
  final List<MemoryKind> kinds;
  @override
  State<_TypeForm> createState() => _TypeFormState();
}

class _TypeFormState extends State<_TypeForm> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _duplicate(String name) =>
      name == context.strings.allLabel ||
      widget.kinds.any(
        (kind) => kind.label.toLowerCase() == name.toLowerCase(),
      );
  @override
  Widget build(BuildContext context) {
    return SheetComposer(
      title: context.strings.newType,
      hint: context.strings.typeName,
      action: context.strings.create,
      controller: _controller,
      fieldKey: const ValueKey('memory-type-name'),
      maxLength: 20,
      maxLines: 1,
      onChanged: (_) => setState(() {}),
      error: _duplicate(_controller.text.trim())
          ? context.strings.typeAlreadyExists
          : null,
      onCommit: () {
        final name = _controller.text.trim();
        if (name.isNotEmpty && !_duplicate(name)) Navigator.pop(context, name);
      },
    );
  }
}
