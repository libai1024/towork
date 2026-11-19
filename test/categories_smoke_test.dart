import 'package:towork/data/repositories/todo_repository.dart';
import 'package:towork/data/repositories/category_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:towork/features/categories/categories_page.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/domain/models/models.dart';
import 'package:towork/theme/app_theme.dart';

/// 分类管理（04-categories.md）冒烟测试：仓库结构操作 + 页面交互。

class _EmptyCategoryRepository extends CategoryRepository {
  _EmptyCategoryRepository() {
    // ignore: invalid_use_of_protected_member
    state = const [];
  }
}

/// 受控 Todo 仓库：统计聚合测试专用，不随历史种子漂移。
class _TinyTodoRepository extends TodoRepository {
  _TinyTodoRepository() {
    final now = DateTime.now();
    // ignore: invalid_use_of_protected_member
    state = [
      Todo(id: 'x1', title: 'a', categoryId: 'cat_stock', createdAt: now),
      Todo(
        id: 'x2',
        title: 'b',
        categoryId: 'cat_stock_position',
        status: TodoStatus.done,
        createdAt: now,
      ),
      Todo(
        id: 'x3',
        title: 'c',
        categoryId: 'cat_stock_position',
        createdAt: now,
      ),
      Todo(id: 'x4', title: 'd', createdAt: now),
    ];
  }
}

Widget _app({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(theme: AppTheme.light, home: const CategoriesPage()),
  );
}

/// 统计格式「{N} 项 {P}%」——历史种子随日期伪随机变化，不断言具体数值。
final _statsPattern = RegExp(r'^\d+ 项 \d+%$');

/// 手机视口（390×844）：Sheet 内容一屏内完整可见。
void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  // ---------------------------------------------------------------------------
  // 仓库：结构与级联（纯逻辑）
  // ---------------------------------------------------------------------------

  group('CategoryRepository 拖拽/层级', () {
    late CategoryRepository repo;
    setUp(() => repo = CategoryRepository());

    test('同级排序：moveCategory 重排一级且序号收敛', () {
      expect(repo.roots.map((e) => e.id), [
        'cat_stock',
        'cat_archive',
        'cat_family',
        'cat_work',
      ]);
      expect(repo.moveCategory('cat_work', null, 0), isTrue);
      expect(repo.roots.first.id, 'cat_work');
      expect(repo.roots.map((e) => e.sortOrder), [0, 1, 2, 3]);
    });

    test('降级为子：无子一级可挂靠；含子一级被拒绝（严格两级）', () {
      expect(repo.moveCategory('cat_family', 'cat_stock', 9999), isTrue);
      expect(repo.byId('cat_family')!.parentId, 'cat_stock');
      // 落点为末尾子分类
      expect(repo.childrenOf('cat_stock').last.id, 'cat_family');
      // 含子分类的一级分类不得再降级（非法第三级）
      expect(repo.moveCategory('cat_stock', 'cat_archive', 9999), isFalse);
      expect(repo.byId('cat_stock')!.parentId, isNull);
    });

    test('提升为一级：子分类拖到一级间隙', () {
      expect(repo.moveCategory('cat_stock_plan', null, 1), isTrue);
      expect(repo.byId('cat_stock_plan')!.parentId, isNull);
      expect(repo.childrenOf('cat_stock').map((e) => e.id), [
        'cat_stock_position',
      ]);
    });

    test('子分类不可作父级（严格两级）', () {
      expect(
        repo.moveCategory('cat_family', 'cat_stock_position', 9999),
        isFalse,
      );
    });

    test('moveWithinSiblings 上移/下移与边界', () {
      expect(repo.moveWithinSiblings('cat_stock', -1), isFalse);
      expect(repo.moveWithinSiblings('cat_stock', 1), isTrue);
      expect(repo.roots[1].id, 'cat_stock');
      // 子分类同级内移动
      expect(repo.moveWithinSiblings('cat_stock_plan', -1), isTrue);
      expect(repo.childrenOf('cat_stock').first.id, 'cat_stock_plan');
    });
  });

  group('CategoryRepository 归档/删除级联', () {
    late CategoryRepository repo;
    setUp(() => repo = CategoryRepository());

    test('归档子树级联，恢复还原', () {
      repo.setArchived('cat_stock', true);
      expect(repo.byId('cat_stock')!.archived, isTrue);
      expect(repo.byId('cat_stock_position')!.archived, isTrue);
      expect(repo.roots.map((e) => e.id), [
        'cat_archive',
        'cat_family',
        'cat_work',
      ]);
      expect(repo.archivedRoots.length, 3);
      repo.setArchived('cat_stock', false);
      expect(repo.byId('cat_stock_position')!.archived, isFalse);
      expect(repo.archivedRoots.length, 2);
    });

    test('restoreAll 快照撤销', () {
      final snapshot = repo.state;
      repo.setArchived('cat_stock', true);
      repo.removeSubtree('cat_family');
      repo.restoreAll(snapshot);
      expect(repo.byId('cat_stock')!.archived, isFalse);
      expect(repo.byId('cat_family'), isNotNull);
    });

    test('删除：子分类提升为一级，待办移到「未分类」', () {
      final todos = TodoRepository();
      todos.reassignTodos({'cat_stock'});
      expect(todos.byId('t11')!.categoryId, isNull);
      repo.removeKeepChildren('cat_stock');
      expect(repo.byId('cat_stock'), isNull);
      expect(repo.byId('cat_stock_position')!.parentId, isNull);
      // 子分类待办保留归属
      expect(todos.byId('t3')!.categoryId, 'cat_stock_position');
    });

    test('删除：一并删除子树与待办', () {
      final todos = TodoRepository();
      final subtree = repo.subtreeIds('cat_stock');
      todos.removeTodosIn(subtree);
      repo.removeSubtree('cat_stock');
      expect(repo.byId('cat_stock_position'), isNull);
      expect(todos.byId('t3'), isNull);
      expect(todos.byId('t11'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 统计聚合（受控数据，04 §8.2）
  // ---------------------------------------------------------------------------

  group('categoryStatsProvider 聚合口径', () {
    test('一级含子分类聚合，子分类仅自身；空分类率为 null', () {
      final container = ProviderContainer(
        overrides: [
          todoListProvider.overrideWith((ref) => _TinyTodoRepository()),
        ],
      );
      addTearDown(container.dispose);

      // 炒股 = 自身 1 open + 持仓 1 open/1 done → 2/1 → 33%
      final stock = container.read(categoryStatsProvider('cat_stock'));
      expect((stock.open, stock.done, stock.completionRate), (2, 1, 33));
      // 持仓仅自身：1/1 → 50%
      final position = container.read(
        categoryStatsProvider('cat_stock_position'),
      );
      expect(
        (position.open, position.done, position.completionRate),
        (1, 1, 50),
      );
      // 无待办分类：率 null（UI 显示「—」）
      final family = container.read(categoryStatsProvider('cat_family'));
      expect((family.open, family.done, family.completionRate), (0, 0, null));
    });
  });

  // ---------------------------------------------------------------------------
  // 页面交互
  // ---------------------------------------------------------------------------

  group('CategoriesPage', () {
    testWidgets('渲染两级树 + 聚合统计 + 归档区收起', (tester) async {
      _usePhoneSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('分类'), findsOneWidget);
      for (final name in ['炒股', '档案馆', '家庭', '工作']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // 一级行统计为含子分类聚合值（04 §3.2），格式「N 项 P%」
      expect(
        find.textContaining(_statsPattern, findRichText: true),
        findsNWidgets(4),
      );
      // 子分类默认收起
      expect(find.text('持仓'), findsNothing);
      // 归档区默认收起
      expect(find.text('已归档 2'), findsOneWidget);
      expect(find.text('健身房打卡'), findsNothing);
      await tester.tap(find.byTooltip('排序分类'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('完成排序'), findsOneWidget);
    });

    testWidgets('展开一级分类显示子分类及自身统计', (tester) async {
      _usePhoneSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('展开子分类').first);
      await tester.pumpAndSettle();
      expect(find.text('持仓'), findsOneWidget);
      expect(find.text('交易计划'), findsOneWidget);
      // 子行显示自身统计：4 条一级行 + 2 条子行
      expect(
        find.textContaining(_statsPattern, findRichText: true),
        findsNWidgets(6),
      );
    });

    testWidgets('新建分类 Sheet：名称/图标/颜色/归属，保存实时入仓库', (tester) async {
      _usePhoneSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('新建分类'));
      await tester.pumpAndSettle();
      expect(find.text('新建分类'), findsOneWidget);
      expect(find.text('图标'), findsOneWidget);
      expect(find.text('颜色'), findsOneWidget);
      expect(find.text('归属'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '读书笔记');
      await tester.pump();
      // 分类使用淡底色，不复用逾期警示红。
      await tester.tap(find.bySemanticsLabel('颜色，米灰，未选中，共 8 项之第 2 项'));
      await tester.pump();
      await tester.tap(find.text('完  成'));
      await tester.pumpAndSettle();

      expect(find.text('读书笔记'), findsOneWidget);
      // 无待办显示「0 项 —」
      expect(find.text('0 项 —'), findsOneWidget);
    });

    testWidgets('新建子分类：归属预选锁定，创建后父级自动展开', (tester) async {
      _usePhoneSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('家庭 更多操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建子分类'));
      await tester.pumpAndSettle();

      expect(find.text('家庭'), findsWidgets); // 归属行预选中
      await tester.enterText(find.byType(TextField), '孩子教育');
      await tester.pump();
      await tester.tap(find.text('完  成'));
      await tester.pumpAndSettle();

      expect(find.text('孩子教育'), findsOneWidget);
    });

    testWidgets('归档带撤销 Toast，归档区计数同步', (tester) async {
      _usePhoneSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('家庭 更多操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('归档'));
      await tester.pumpAndSettle();

      expect(find.text('「家庭」已归档，新建待办时不会再出现'), findsOneWidget);
      expect(find.text('已归档 3'), findsOneWidget);
      expect(find.text('家庭'), findsNothing);

      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(find.text('家庭'), findsOneWidget);
      expect(find.text('已归档 2'), findsOneWidget);
      // 排空 Toast 计时器
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('删除级联确认：待办移到未分类、子分类提升为一级', (tester) async {
      _usePhoneSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('炒股 更多操作'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(find.text('删除「炒股」？'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'里面有\d+ 条待办、2 个子分类。')),
        findsOneWidget,
      );
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // 炒股消失，子分类提升为一级
      expect(find.text('炒股'), findsNothing);
      expect(find.text('持仓'), findsOneWidget);
      expect(find.text('交易计划'), findsOneWidget);
      expect(find.text('已删除「炒股」'), findsOneWidget);

      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(find.text('炒股'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('长按进入排序模式：手柄与规则提示，「完成」退出', (tester) async {
      _usePhoneSurface(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.longPress(find.text('家庭'));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.gripVertical), findsWidgets);
      expect(find.text('拖到一级行之间 = 同级排序 / 提升为一级'), findsOneWidget);
      expect(find.text('完成'), findsOneWidget);

      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.gripVertical), findsNothing);
    });

    testWidgets('空状态：示例一键创建三个一级分类', (tester) async {
      _usePhoneSurface(tester);
      await tester.pumpWidget(
        _app(
          overrides: [
            categoryListProvider.overrideWith(
              (ref) => _EmptyCategoryRepository(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无分类'), findsOneWidget);
      expect(find.text('将创建炒股、档案馆、家庭'), findsOneWidget);

      await tester.tap(find.text('创建示例分类'));
      await tester.pumpAndSettle();

      expect(find.text('炒股'), findsOneWidget);
      expect(find.text('档案馆'), findsOneWidget);
      expect(find.text('家庭'), findsOneWidget);
    });
  });
}
