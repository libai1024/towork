import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/providers.dart';
import 'package:towork/features/settings/settings_page.dart';
import 'package:towork/features/settings/widgets/settings_shared.dart';
import 'package:towork/theme/app_theme.dart';

/// 开关行语义合并：整行 + CupertinoSwitch 只暴露一个带 toggled
/// 状态的开关节点（此前「行按钮 + 开关」重复播报两个焦点），
/// 且语义激活 / 行点按 / 开关本体三条路径都能切换。
void main() {
  testWidgets('switch rows expose one merged toggle node', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsPage)),
    );

    // 「免记忆模式」在首屏：合并前 行按钮 + 开关 各播报一次，
    // 合并后只剩一个开关节点。
    final freezeNode = find.bySemanticsLabel('免记忆模式');
    expect(freezeNode, findsOneWidget);
    final freezeData = tester.getSemantics(freezeNode).getSemanticsData();
    expect(
      freezeData.flagsCollection.isToggled,
      Tristate.isFalse,
      reason: '默认关闭',
    );
    expect(freezeData.hasAction(SemanticsAction.tap), isTrue);

    // 滚到通知分组，「截止提醒」同样只有一个节点。
    await tester.scrollUntilVisible(
      find.text('截止提醒'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final dueNode = find.bySemanticsLabel('截止提醒');
    expect(dueNode, findsOneWidget);
    final data = tester.getSemantics(dueNode).getSemanticsData();
    expect(data.flagsCollection.isToggled, Tristate.isTrue, reason: '默认开启');
    expect(data.hasAction(SemanticsAction.tap), isTrue, reason: '读屏双击可切换');

    // 语义激活路径：通过语义树执行 tap（VoiceOver 双击等效）。
    final node = tester.getSemantics(dueNode);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    expect(container.read(notifyDueEnabledProvider), isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getSemantics(dueNode).getSemanticsData().flagsCollection.isToggled,
      Tristate.isFalse,
      reason: '关闭后状态同步',
    );

    // 行点按路径（物理点击行任意位置仍切换）。
    await tester.tap(find.text('截止提醒'), warnIfMissed: false);
    await tester.pump();
    expect(container.read(notifyDueEnabledProvider), isTrue);

    // 开关本体路径仍可直接点按（点「截止提醒」行内的那一个开关）。
    final dueSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('截止提醒'),
        matching: find.byType(SettingsSwitchRow),
      ),
      matching: find.byType(CupertinoSwitch),
    );
    await tester.tap(dueSwitch);
    await tester.pump();
    expect(container.read(notifyDueEnabledProvider), isFalse);

    // 「每日晨报」行点按是「时间选择/开启」而非切换：保持复合语义
    // （行节点 + 开关节点两个焦点），但开关播报名与行名不再相同，
    // 读屏可区分「打开时间选择」与「切换开关」。
    expect(find.bySemanticsLabel('每日晨报开关'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^每日晨报')).evaluate().length,
      2,
      reason: '行节点与开关节点各一个，且名称可区分',
    );
    semantics.dispose();
  });
}
