import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:towork/app/workspace_clock.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
  );

  test(
    'ticks align to minute and date boundaries rather than creation time',
    () {
      fakeAsync((async) {
        final start = DateTime(2026, 9, 23, 23, 59, 59, 500);
        final container = ProviderContainer(
          overrides: [
            workspaceNowProvider.overrideWithValue(
              () => start.add(async.elapsed),
            ),
          ],
        );
        final subscription = container.listen(
          workspaceClockProvider,
          (_, _) {},
        );
        expect(subscription.read().now, start);
        async.elapse(const Duration(milliseconds: 499));
        expect(subscription.read().now, start);
        async.elapse(const Duration(milliseconds: 1));
        expect(subscription.read().now, DateTime(2026, 9, 24));
        async.elapse(const Duration(minutes: 1));
        expect(subscription.read().now, DateTime(2026, 9, 24, 0, 1));
        final controller = container.read(workspaceClockProvider.notifier);
        subscription.close();
        async.elapse(Duration.zero);
        expect(controller.mounted, isFalse);
        expect(async.pendingTimers, isEmpty);
        container.dispose();
        async.elapse(Duration.zero); // Drain Riverpod's disposal scheduler.
        expect(async.pendingTimers, isEmpty);
      });
    },
  );

  test('backgrounding cancels ticks and resume reads fresh wall time', () {
    fakeAsync((async) {
      final start = DateTime(2026, 9, 23, 23, 59, 40);
      final container = ProviderContainer(
        overrides: [
          workspaceNowProvider.overrideWithValue(
            () => start.add(async.elapsed),
          ),
        ],
      );
      final subscription = container.listen(workspaceClockProvider, (_, _) {});
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(subscription.read().isActive, isFalse);
      expect(async.pendingTimers, isEmpty);
      async.elapse(const Duration(hours: 8));
      expect(subscription.read().now, start);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(subscription.read().now, start.add(const Duration(hours: 8)));
      expect(subscription.read().isActive, isTrue);
      expect(async.pendingTimers, hasLength(1));
      final controller = container.read(workspaceClockProvider.notifier);
      subscription.close();
      container.dispose();
      async.elapse(Duration.zero); // Drain Riverpod's disposal scheduler.
      expect(async.pendingTimers, isEmpty);
      // Disposed clocks are detached from lifecycle notifications and refresh.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      controller.refresh();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test(
    'explicit refresh handles wall-clock changes and schedules a new boundary',
    () {
      fakeAsync((async) {
        var wallTime = DateTime.utc(2026, 9, 23, 10, 2, 30);
        final controller = WorkspaceClock(
          now: () => wallTime,
          binding: binding,
        );
        WorkspaceTime? latest;
        final remove = controller.addListener((value) => latest = value);
        wallTime = DateTime.utc(2026, 9, 24, 7, 4, 50);
        controller.refresh();
        expect(latest!.now, wallTime);
        expect(async.pendingTimers, hasLength(1));
        expect(
          async.pendingTimers.single.duration,
          const Duration(seconds: 10),
        );
        remove();
        controller.dispose();
        expect(async.pendingTimers, isEmpty);
      });
    },
  );
}
