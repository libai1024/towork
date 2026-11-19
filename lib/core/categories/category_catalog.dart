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
const categoryIconOptions = <CategoryIconOption>[
  CategoryIconOption('trending-up', LucideIcons.trendingUp, '上涨曲线'),
  CategoryIconOption('archive', LucideIcons.archive, '归档盒'),
  CategoryIconOption('home', LucideIcons.home, '家'),
  CategoryIconOption('briefcase', LucideIcons.briefcase, '公文包'),
  CategoryIconOption('heart', LucideIcons.heart, '心形'),
  CategoryIconOption('book-open', LucideIcons.bookOpen, '翻开的书'),
  CategoryIconOption('wallet', LucideIcons.wallet, '钱包'),
  CategoryIconOption('shopping-cart', LucideIcons.shoppingCart, '购物车'),
  CategoryIconOption('utensils', LucideIcons.utensils, '餐具'),
  CategoryIconOption('plane', LucideIcons.plane, '飞机'),
  CategoryIconOption('dumbbell', LucideIcons.dumbbell, '哑铃'),
  CategoryIconOption('graduation-cap', LucideIcons.graduationCap, '学位帽'),
  CategoryIconOption('music', LucideIcons.music, '音符'),
  CategoryIconOption('camera', LucideIcons.camera, '相机'),
  CategoryIconOption('gift', LucideIcons.gift, '礼物'),
  CategoryIconOption('car', LucideIcons.car, '汽车'),
  CategoryIconOption('paw-print', LucideIcons.pawPrint, '爪印'),
  CategoryIconOption('leaf', LucideIcons.leaf, '叶子'),
  CategoryIconOption('star', LucideIcons.star, '星星'),
  CategoryIconOption('flag', LucideIcons.flag, '旗帜'),
  CategoryIconOption('code-2', LucideIcons.code2, '代码'),
  CategoryIconOption('pen-tool', LucideIcons.penTool, '钢笔'),
  CategoryIconOption('users', LucideIcons.users, '人物'),
  CategoryIconOption('folder', LucideIcons.folder, '文件夹'),
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
  CategoryColorOption('blue', '雾蓝', c.categoryPalette[0]),
  CategoryColorOption('red', '米灰', c.categoryPalette[1]),
  CategoryColorOption('green', '雾绿', c.categoryPalette[2]),
  CategoryColorOption('yellow', '麦色', c.categoryPalette[3]),
  CategoryColorOption('orange', '陶土', c.categoryPalette[4]),
  CategoryColorOption('purple', '灰紫', c.categoryPalette[5]),
  CategoryColorOption('cyan', '青灰', c.categoryPalette[6]),
  CategoryColorOption('pink', '暖灰', c.categoryPalette[7]),
];

/// Category identity comes from a quiet surface; all glyphs share readable ink.
Color categoryIconColor(AppColors c, Color color) => c.categoryForeground;

/// The editor uses dark, muted source swatches so every option is distinguishable.
Color categoryCheckColor(AppColors c, Color color) => Colors.white;
