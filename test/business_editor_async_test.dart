import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/core/widgets/app_button.dart';
import 'package:towork/core/widgets/app_toast.dart';
import 'package:towork/domain/models/data_table.dart';
import 'package:towork/domain/workspace/workspace_commands.dart';
import 'package:towork/features/data_tables/widgets/field_editors.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  testWidgets(
    'awaits save, blocks duplicate taps, preserves failed draft and permits retry',
    (tester) async {
      final first = Completer<void>();
      var calls = 0;
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('打开'),
                onPressed: () async {
                  result = await showFieldEditor(
                    context,
                    column: DataColumnDef(name: '名称', type: 'text'),
                    current: '原文',
                    onSave: (value) async {
                      calls++;
                      if (calls == 1) await first.future;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '保留草稿');
      final save = find.widgetWithText(AppButton, '保存');
      await tester.tap(save);
      await tester.pump();
      expect(calls, 1);
      expect(result, isNull);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.tap(save, warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);
      first.completeError(
        const WorkspaceFailure(WorkspaceFailureCode.storageUnavailable),
      );
      await tester.pumpAndSettle();
      expect(find.text('保留草稿'), findsOneWidget);
      expect(result, isNull);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(result, '保留草稿');
      expect(tester.takeException(), isNull);
      AppToast.dismiss();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
