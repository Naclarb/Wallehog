import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import '../support/memory_repository.dart';

void main() {
  testWidgets('小猪长按拖动并吸附边缘', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = RecordsController(MemoryRepository());
    addTearDown(c.dispose);
    await c.load();
    await tester.pumpWidget(WallehogApp(controller: c));
    await tester.pumpAndSettle();
    final pig = find.byKey(const Key('draggablePig'));
    final start = tester.getCenter(pig);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(-150, 300));
    await tester.pump();
    expect(tester.getCenter(pig).dy, greaterThan(start.dy + 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(pig).dx, closeTo(0, 1));
  });
  for (final size in [const Size(360, 800), const Size(390, 844)]) {
    testWidgets('紧凑首页 $size 完整记录连续滚动与手柄原尺寸', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.reset);
      final c = RecordsController(MemoryRepository());
      addTearDown(c.dispose);
      await c.load();
      await c.createGoal('PS5', 400000, style: 'ps5');
      for (final amount in List.generate(30, (i) => (i + 1) * 100)) {
        final now = DateTime.now();
        await c.save(
          SavingRecord(
            kind: DecisionKind.quick,
            description: '',
            amountMinor: amount,
            occurredOn: dateKey(now),
            createdAt: now,
            updatedAt: now,
            today: now,
          ),
        );
      }
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const Key('goalItem'))).width, 128);
      expect(
        tester.getSize(find.byKey(const Key('bottomNavigationContent'))).height,
        56,
      );
      final nav = tester.getRect(
        find.byKey(const Key('bottomNavigationContent')),
      );
      for (final r in c.records) {
        final row = find.byKey(ValueKey('recentSaving_${r.id}'));
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(tester.getRect(row).top, lessThan(nav.top));
        expect(row.hitTestable(), findsOneWidget);
      }
      expect(
        tester.getRect(find.byKey(const Key('goalCard'))).bottom,
        lessThan(0),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final reduced in [false, true]) {
    testWidgets('保存反馈与失败保护，减少动画=$reduced', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repo = MemoryRepository();
      final c = RecordsController(repo);
      addTearDown(c.dispose);
      await c.load();
      await c.createGoal('PS5', 400000, style: 'ps5');
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expression')), '2');
      await tester.pumpAndSettle();
      repo.fail = true;
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<Transform>(find.byKey(const Key('roomPigBounce')))
            .transform
            .storage[13],
        0,
      );
      expect(c.summary.savedMinor, 0);
      repo.fail = false;
      await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pump();
      for (
        var frame = 0;
        frame < 60 &&
            find.byKey(const Key('depositFeedback')).evaluate().isEmpty;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final offset = tester
          .widget<Transform>(find.byKey(const Key('roomPigBounce')))
          .transform
          .storage[13];
      final scale = tester
          .widget<Transform>(find.byKey(const Key('addPulse')))
          .transform
          .storage[0];
      // 金币尚未入槽，原猪不能提前跳跃。
      expect(offset, equals(0));
      expect(scale, reduced ? equals(1) : lessThan(1));
      expect(c.summary.savedMinor, 200);
      expect(c.records.length, 1);
      await tester.pump(const Duration(milliseconds: 800));
      final landedOffset = tester
          .widget<Transform>(find.byKey(const Key('roomPigBounce')))
          .transform
          .storage[13];
      expect(landedOffset, reduced ? equals(0) : lessThan(0));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Transform>(find.byKey(const Key('addPulse')))
            .transform
            .storage[0],
        1,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
