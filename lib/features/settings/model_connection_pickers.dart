part of 'model_connection_page.dart';

extension _ModelConnectionPickers on _ModelConnectionPageState {
  Future<void> _pickRegion() async {
    final region = await AppSheet.show<ProviderRegion>(
      context,
      title: context.strings.serviceRegion,
      child: Builder(
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ProviderRegion.values)
              SheetOptionRow(
                title: option == ProviderRegion.china
                    ? context.strings.china
                    : context.strings.international,
                selected: _region == option,
                onTap: () => Navigator.of(sheet).pop(option),
              ),
          ],
        ),
      ),
    );
    if (!mounted || !_fieldsEnabled || region == null || region == _region) {
      return;
    }
    _region = region;
    _key.clear();
    _edited(credentials: true);
  }

  void _pickProduct() {
    AppSheet.show<void>(
      context,
      title: context.strings.chooseProvider,
      child: Builder(
        builder: (sheet) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final descriptor in ProviderCatalog.all)
                ModelProviderOption(
                  key: ValueKey('provider-${descriptor.kind.wireId}'),
                  descriptor: descriptor,
                  selected: descriptor.kind == _product,
                  onTap: () {
                    Navigator.of(sheet).pop();
                    _selectProduct(descriptor.kind);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
