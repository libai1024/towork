import 'package:towork/l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';

/// 分类图标策展集与 8 色盘（04-categories.md §3.4 / §5.3 / §7）。

/// 策展图标：Lucide 键 + IconData + 中文语义名（屏幕阅读器朗读用，04 §7）。
class CategoryIconOption {
  const CategoryIconOption(this.key, this.icon, this.label);

  final String key;
  final IconData icon;
  final String label;
}

/// 24 个策展图标（04 §3.4 名单），默认选中 folder。
List<CategoryIconOption> get categoryIconOptions => <CategoryIconOption>[
  CategoryIconOption(
    'trending-up',
    LucideIcons.trendingUp,
    strings.upwardTrend,
  ),
  CategoryIconOption('archive', LucideIcons.archive, strings.archiveBox),
  CategoryIconOption('home', LucideIcons.home, strings.home),
  CategoryIconOption('briefcase', LucideIcons.briefcase, strings.briefcase),
  CategoryIconOption('heart', LucideIcons.heart, strings.heart),
  CategoryIconOption('book-open', LucideIcons.bookOpen, strings.openBook),
  CategoryIconOption('wallet', LucideIcons.wallet, strings.wallet),
  CategoryIconOption(
    'shopping-cart',
    LucideIcons.shoppingCart,
    strings.shoppingCart,
  ),
  CategoryIconOption('utensils', LucideIcons.utensils, strings.cutlery),
  CategoryIconOption('plane', LucideIcons.plane, strings.plane),
  CategoryIconOption('dumbbell', LucideIcons.dumbbell, strings.dumbbell),
  CategoryIconOption(
    'graduation-cap',
    LucideIcons.graduationCap,
    strings.graduationCap,
  ),
  CategoryIconOption('music', LucideIcons.music, strings.note),
  CategoryIconOption('camera', LucideIcons.camera, strings.camera),
  CategoryIconOption('gift', LucideIcons.gift, strings.gift),
  CategoryIconOption('car', LucideIcons.car, strings.car),
  CategoryIconOption('paw-print', LucideIcons.pawPrint, strings.pawPrint),
  CategoryIconOption('leaf', LucideIcons.leaf, strings.leaf),
  CategoryIconOption('star', LucideIcons.star, strings.star),
  CategoryIconOption('flag', LucideIcons.flag, strings.flag),
  CategoryIconOption('code-2', LucideIcons.code2, strings.code),
  CategoryIconOption('pen-tool', LucideIcons.penTool, strings.pen),
  CategoryIconOption('users', LucideIcons.users, strings.person),
  CategoryIconOption('folder', LucideIcons.folder, strings.folder),
];

/// 按键取图标，未知键回落 folder（04 §8.1 缺省）。
IconData categoryIconFor(String? key) {
  for (final option in categoryIconOptions) {
    if (option.key == key) return option.icon;
  }
  return LucideIcons.folder;
}

/// 8 色盘条目（规范 §1.5 预设 8 色，全部经 AppColors token 取色）。
class CategoryColorOption {
  const CategoryColorOption(this.key, this.name, this.color);

  final String key;
  final String name;
  final Color color;
}

List<CategoryColorOption> categoryPaletteOf(AppColors c) => [
  CategoryColorOption('blue', strings.mistBlue, c.categoryPalette[0]),
  CategoryColorOption('red', strings.stone, c.categoryPalette[1]),
  CategoryColorOption('green', strings.sage, c.categoryPalette[2]),
  CategoryColorOption('yellow', strings.wheat, c.categoryPalette[3]),
  CategoryColorOption('orange', strings.terracotta, c.categoryPalette[4]),
  CategoryColorOption('purple', strings.lavenderGray, c.categoryPalette[5]),
  CategoryColorOption('cyan', strings.slate, c.categoryPalette[6]),
  CategoryColorOption('pink', strings.warmGray, c.categoryPalette[7]),
];

/// Category identity comes from a quiet surface; all glyphs share readable ink.
Color categoryIconColor(AppColors c, Color color) => c.categoryForeground;

/// The editor uses dark, muted source swatches so every option is distinguishable.
Color categoryCheckColor(AppColors c, Color color) => Colors.white;
