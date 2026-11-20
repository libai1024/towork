import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/ai/model_failure_text.dart';
import '../../../core/ai/model_identity.dart';
import '../../../core/widgets/workspace_nav_bar.dart';
import '../../../domain/ai/model_gateway.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'model_action_button.dart';
import 'settings_shared.dart';

class ModelDirectorySheet extends StatefulWidget {
  const ModelDirectorySheet({
    super.key,
    required this.load,
    required this.current,
    required this.product,
    this.cached,
    required this.onLoaded,
  });
  final Future<List<String>> Function(ModelCancellation) load;
  final List<String>? cached;
  final ValueChanged<List<String>> onLoaded;
  final String current;
  final ProviderKind product;

  @override
  State<ModelDirectorySheet> createState() => _ModelDirectorySheetState();
}

class _ModelDirectorySheetState extends State<ModelDirectorySheet> {
  final _search = TextEditingController();
  List<String> _items = [];
  String? _error;
  ModelCancellation? _request;
  @override
  void initState() {
    super.initState();
    if (widget.cached == null) {
      _fetch();
    } else {
      _items = widget.cached!;
    }
  }

  Future<void> _fetch() async {
    if (_request != null) return;
    final request = ModelCancellation();
    setState(() {
      _request = request;
      _error = null;
    });
    try {
      final items = await widget.load(request);
      if (!mounted || request.isCancelled) return;
      widget.onLoaded(items);
      setState(() => _items = items);
    } catch (error) {
      if (!mounted || request.isCancelled) return;
      setState(
        () => _error =
            error is ModelFailure &&
                (error.statusCode == 404 || error.statusCode == 405)
            ? context.strings.thisApiDoesntListModelsEnterA
            : describeModelSettingsError(error),
      );
    } finally {
      if (mounted) setState(() => _request = null);
    }
  }

  @override
  void dispose() {
    _request?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matches = _items
        .where((id) => id.toLowerCase().contains(query))
        .toList();
    final status =
        _error ??
        (_request != null
            ? context.strings.fetchingModels
            : matches.isEmpty
            ? (query.isEmpty
                  ? context.strings.noAvailableModels
                  : context.strings.noMatchingModels)
            : null);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 340),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status != null)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    status,
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.of(context).labelSecondary,
                    ),
                  ),
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final id = matches[index];
                  return SheetOptionRow(
                    title: id,
                    leading: ProviderLogo(widget.product),
                    selected: id == widget.current,
                    onTap: () => Navigator.of(context).pop(id),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: WorkspaceSearchField(
                    controller: _search,
                    hint: context.strings.searchModels,
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(_search.clear),
                  ),
                ),
                ModelActionButton(
                  label: context.strings.refreshModelList,
                  icon: LucideIcons.refreshCw,
                  onPressed: _request == null ? _fetch : null,
                  loading: _request != null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
