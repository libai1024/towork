import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/data/update/release_history_source.dart';
import 'package:towork/features/update/release_history_view.dart';
import 'package:towork/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'installed patch is expanded and older releases open independently',
    (tester) async {
      final entries = await bundledReleaseHistory();
      expect(
        entries.map((e) => e.id).toSet(),
        containsAll(['1/0', '6/0', '13/2', '14/11', '16/0']),
      );
      expect(entries.any((e) => e.build == 5), isFalse);
      final latest = entries.first;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReleaseHistoryView(entries: entries, currentId: latest.id),
            ),
          ),
        ),
      );
      expect(find.text('当前版本'), findsOneWidget);
      expect(find.text(latest.notes.last), findsOneWidget);
      final old = entries[1];
      expect(find.text(old.notes.first), findsNothing);
      await tester.tap(find.text(old.title));
      await tester.pumpAndSettle();
      expect(find.text(old.notes.first), findsOneWidget);
      await tester.tap(find.text(old.title));
      await tester.pumpAndSettle();
      expect(find.text(old.notes.first), findsNothing);
    },
  );
}
