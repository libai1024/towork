part of 'category_edit_sheet.dart';

extension _CategoryAppearancePicker on _CategoryEditSheetState {
  /// 24 图标策展集网格（6 列）：选中态 1px brand 描边 + 图标转 brand。
  Widget _iconGrid(AppColors c) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: ((constraints.maxWidth + 8) / 52).floor().clamp(
          1,
          MediaQuery.sizeOf(context).width >= 900 ? 8 : 6,
        ),
        mainAxisExtent: 44,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final option in categoryIconOptions)
            Semantics(
              label: context.strings.iconIcongrid(option.label),
              selected: option.key == _iconKey,
              child: AppPressable(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _selectIcon(option.key),
                child: AnimatedContainer(
                  duration: AppMotion.tabSwitch,
                  decoration: BoxDecoration(
                    color: c.fill1,
                    borderRadius: BorderRadius.circular(16),
                    border: option.key == _iconKey
                        ? Border.all(color: c.brand, width: 1)
                        : null,
                  ),
                  child: Icon(
                    option.icon,
                    size: 20,
                    color: option.key == _iconKey ? c.brand : c.labelSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 28px color swatches retain a 44px hit target.
  Widget _colorPalette(AppColors c) {
    final palette = categoryPaletteOf(c);
    return Wrap(
      runSpacing: 8,
      children: [
        for (var i = 0; i < palette.length; i++)
          Semantics(
            label: context.strings.colorItemOf(
              palette[i].name,
              _customColor == null && palette[i].key == _colorKey
                  ? context.strings.selected
                  : context.strings.notSelected,
              palette.length,
              i + 1,
            ),
            child: AppPressable(
              minSize: 44,
              borderRadius: AppRadii.brFull,
              onTap: () => _selectColor(palette[i].key),
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: AnimatedScale(
                    scale: _customColor == null && palette[i].key == _colorKey
                        ? 1.1
                        : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette[i].color,
                        shape: BoxShape.circle,
                      ),
                      child: _customColor == null && palette[i].key == _colorKey
                          ? Icon(
                              LucideIcons.check,
                              size: 12,
                              color: categoryCheckColor(c, palette[i].color),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
