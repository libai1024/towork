import '../../domain/models/models.dart';
import 'seed_palette.dart';

List<Category> seedCategories() {
  return [
    Category(
      id: 'cat_stock',
      name: '炒股',
      color: SeedPalette.red,
      iconKey: 'trending-up',
      sortOrder: 0,
    ),
    Category(
      id: 'cat_stock_position',
      name: '持仓',
      color: SeedPalette.red,
      iconKey: 'wallet',
      parentId: 'cat_stock',
      sortOrder: 0,
    ),
    Category(
      id: 'cat_stock_plan',
      name: '交易计划',
      color: SeedPalette.orange,
      iconKey: 'pen-tool',
      parentId: 'cat_stock',
      sortOrder: 1,
    ),
    Category(
      id: 'cat_archive',
      name: '档案馆',
      color: SeedPalette.cyan,
      iconKey: 'archive',
      sortOrder: 1,
    ),
    Category(
      id: 'cat_archive_in',
      name: '接收登记',
      color: SeedPalette.cyan,
      iconKey: 'book-open',
      parentId: 'cat_archive',
      sortOrder: 0,
    ),
    Category(
      id: 'cat_archive_lend',
      name: '借阅',
      color: SeedPalette.brand,
      iconKey: 'users',
      parentId: 'cat_archive',
      sortOrder: 1,
    ),
    Category(
      id: 'cat_family',
      name: '家庭',
      color: SeedPalette.green,
      iconKey: 'home',
      sortOrder: 2,
    ),
    Category(
      id: 'cat_work',
      name: '工作',
      color: SeedPalette.brand,
      iconKey: 'briefcase',
      sortOrder: 3,
    ),
    Category(
      id: 'cat_gym',
      name: '健身房打卡',
      color: SeedPalette.pink,
      iconKey: 'dumbbell',
      sortOrder: 4,
      archived: true,
    ),
    Category(
      id: 'cat_travel',
      name: '旅行清单',
      color: SeedPalette.purple,
      iconKey: 'plane',
      sortOrder: 5,
      archived: true,
    ),
  ];
}
