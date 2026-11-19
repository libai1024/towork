import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/memory_persistence_provider.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/domain/repositories/memory_persistence.dart';
import 'package:towork/features/memory/memory_page.dart';
import 'package:towork/features/memory/widgets/memory_list_row.dart';
import 'package:towork/theme/app_theme.dart';

import '../../support/fake_memory_persistence.dart';

/// 记忆页生产模式：memoryVaultProvider 指向 FakeMemoryPersistence 支撑的
/// MemoryVaultController，列表与写入全部落在持久层。
void main() {
  Future<ProviderContainer> pumpProduction(
    WidgetTester tester,
    FakeMemoryPersistence fake,
  ) async {
    final container = ProviderContainer(
      overrides: [memoryPersistenceProvider.overrideWith((ref) async => fake)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const MemoryPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('生产列表来自持久层且新增落库（不经过演示 store）', (tester) async {
    final fake = FakeMemoryPersistence();
    await fake.remember(content: '用户常驻上海', kindId: 'fact');
    await fake.remember(content: '用户偏好安静的环境', kindId: 'preference');
    final container = await pumpProduction(tester, fake);

    final vault = container.read(memoryVaultProvider).value;
    expect(vault, isNotNull);
    expect(vault!.state, hasLength(2));

    // 列表渲染持久层内容，而非演示种子数据。
    expect(find.byType(MemoryListRow), findsNWidgets(2));
    expect(find.text('事实 1'), findsOneWidget);
    expect(find.text('偏好 1'), findsOneWidget);
    expect(find.textContaining('茅台'), findsNothing);
    // 自定义类型入口仅演示模式提供。
    expect(find.byTooltip('新增类型'), findsNothing);

    final demoCountBefore = container.read(memoryListProvider).length;

    await tester.tap(find.bySemanticsLabel('新增记忆').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '生产新增的一条记忆');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('已记住'), findsOneWidget);
    final stored = await fake.list();
    expect(stored, hasLength(3));
    expect(stored.map((r) => r.content), contains('生产新增的一条记忆'));
    expect(vault.state, hasLength(3));
    expect(find.text('事实 2'), findsOneWidget);
    // 演示内存 store 完全未被触碰。
    expect(container.read(memoryListProvider).length, demoCountBefore);
  });

  testWidgets('删除撤销改为重新记住：内容恢复且使用新 ID', (tester) async {
    final fake = FakeMemoryPersistence();
    await fake.remember(content: '用户常驻上海', kindId: 'fact');
    await fake.remember(content: '另一条事实', kindId: 'fact');
    await pumpProduction(tester, fake);

    final card = find.byKey(const ValueKey('fake_mem_0'));
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('记忆详情'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条记忆？'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(card, findsNothing);
    expect(find.byType(MemoryListRow), findsOneWidget);
    expect(await fake.list(), hasLength(1));

    await tester.tap(find.text('重新记住'));
    await tester.pumpAndSettle();

    final restored = await fake.list();
    expect(restored, hasLength(2));
    expect(restored.map((r) => r.content), contains('用户常驻上海'));
    // 生产撤销走 addManual，恢复的是内容而非原 ID。
    expect(restored.any((r) => r.id == 'fake_mem_0'), isFalse);
    expect(find.textContaining('用户常驻上海'), findsOneWidget);
    expect(find.text('事实 2'), findsOneWidget);
  });

  testWidgets('暂停时手动新增被拒绝并有提示，恢复后可写', (tester) async {
    final fake = FakeMemoryPersistence();
    await fake.remember(content: '存量记忆', kindId: 'fact');
    await pumpProduction(tester, fake);

    await tester.tap(find.bySemanticsLabel('免记忆模式，当前关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开启'));
    await tester.pumpAndSettle();

    expect(await fake.paused(), isTrue);
    expect(find.text('免记忆模式已开启，新对话不会写入记忆库'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('新增记忆').first);
    await tester.pumpAndSettle();
    expect(find.text('免记忆模式下不可新增'), findsOneWidget);
    expect(await fake.list(), hasLength(1));

    // 持久层同样拒绝任何写入（包括绕过界面的显式记住）。
    await expectLater(
      fake.remember(content: '显式记住', kindId: 'fact'),
      throwsA(
        isA<MemoryPersistenceFailure>().having(
          (f) => f.code,
          'code',
          MemoryPersistenceFailureCode.paused,
        ),
      ),
    );

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('已恢复记忆'), findsOneWidget);
    expect(await fake.paused(), isFalse);
    expect(find.text('免记忆模式已开启，新对话不会写入记忆库'), findsNothing);
  });

  testWidgets('持久层 validation 失败时表单保留输入，重试后成功', (tester) async {
    final fake = FakeMemoryPersistence();
    await fake.remember(content: '存量记忆', kindId: 'fact');
    await pumpProduction(tester, fake);

    fake.failNextWith(MemoryPersistenceFailureCode.validation);
    await tester.tap(find.bySemanticsLabel('新增记忆').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '这条暂时会被拒绝');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('内容或类型无效'), findsOneWidget);
    // 弹层未关闭，输入保留，持久层未落库。
    expect(find.text('保存'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      '这条暂时会被拒绝',
    );
    expect(await fake.list(), hasLength(1));

    // 等轻提示消失后重试，恢复成功路径。
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('已记住'), findsOneWidget);
    expect(find.text('保存'), findsNothing);
    final stored = await fake.list();
    expect(stored, hasLength(2));
    expect(stored.map((r) => r.content), contains('这条暂时会被拒绝'));
  });

  testWidgets('演示模式回归：memoryVaultProvider 为 null 且走原内存 store', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const MemoryPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    final scope = ProviderScope.containerOf(
      tester.element(find.byType(MemoryPage)),
    );
    expect(scope.read(memoryVaultProvider).value, isNull);
    expect(find.byTooltip('新增类型'), findsOneWidget);

    final before = scope.read(memoryListProvider).length;
    await tester.tap(find.bySemanticsLabel('新增记忆').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '演示新增的一条');
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('已记住'), findsOneWidget);
    final after = scope.read(memoryListProvider);
    expect(after.length, before + 1);
    expect(after.first.content, '演示新增的一条');
  });
}
