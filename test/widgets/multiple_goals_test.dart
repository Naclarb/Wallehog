import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import '../support/memory_repository.dart';

void main() {
  testWidgets('两张心愿循环且打开录入不跳动', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = RecordsController(MemoryRepository());
    addTearDown(c.dispose);
    await c.load();
    await c.createGoal('A', 10000);
    await c.createGoal('B', 20000);
    await c.selectGoal(c.goals.first.id!);
    await tester.pumpWidget(WallehogApp(controller: c));
    await tester.pumpAndSettle();
    for (final name in ['B', 'A', 'B', 'A']) {
      await tester.drag(
        find.byKey(const Key('goalCarousel')),
        const Offset(0, 100),
      );
      await tester.pumpAndSettle();
      expect(c.goal!.name, name);
    }
    final before = tester.getRect(find.byKey(const Key('goalCard')));
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    expect(c.goal!.name, 'A');
    expect(tester.getRect(find.byKey(const Key('goalCard'))), before);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const Key('goalCard'))), before);
  });

  testWidgets('旋转或调整窗口不改变当前心愿', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = RecordsController(MemoryRepository());
    addTearDown(c.dispose);
    await c.load();
    await c.createGoal('耳机', 100000, style: 'headphones');
    await c.createGoal('PS5', 400000, style: 'ps5');
    final selected = c.goal!.id;
    await tester.pumpWidget(WallehogApp(controller: c));
    await tester.pumpAndSettle();
    for (final size in [
      const Size(1219, 813),
      const Size(813, 1219),
      const Size(360, 800),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(c.goal!.id, selected);
      expect(find.text('PS5'), findsOneWidget);
    }
  });
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(1219, 813),
  ]) {
    testWidgets('多心愿滑动、选中录入、样式编辑与原地小猪 $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = RecordsController(MemoryRepository());
      addTearDown(c.dispose);
      await c.load();
      await c.createGoal('PS5', 400000, style: 'ps5');
      await c.createGoal('一副好耳机', 100000, style: 'headphones');
      await c.createGoal('相机', 100000, style: 'camera');
      await c.selectGoal(c.goals.first.id!);
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('roomPig'))).height,
        inInclusiveRange(60, 85),
      );
      await tester.tap(find.byKey(const Key('nextGoal')));
      await tester.pumpAndSettle();
      expect(c.goal!.style, 'headphones');
      await tester.drag(
        find.byKey(const Key('goalCarousel')),
        const Offset(0, 100),
      );
      await tester.pumpAndSettle();
      expect(c.goal!.style, 'camera');
      await tester.drag(
        find.byKey(const Key('goalCarousel')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(c.goal!.style, 'headphones');
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expression')), '27');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(c.goalProgressMinor, 2700);
      expect(c.goals.first.progressMinor(c.records), 0);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('previousGoal')));
      await tester.pumpAndSettle();
      expect(c.goal!.style, 'ps5');
      expect(c.goalProgressMinor, 0);
      expect(c.summary.savedMinor, 2700);
      await tester.tap(find.byKey(const Key('addGoal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('style_camera')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('goalTargetInput')), '1000');
      await tester.tap(find.byKey(const Key('saveGoal')));
      await tester.pumpAndSettle();
      expect(c.goals.length, 4);
      expect(c.goal!.style, 'camera');
      expect(c.goal!.name, '我的相机');
      await tester.tap(find.byKey(const Key('pigRoomTab')));
      await tester.pump();
      expect(find.byKey(const Key('pigRoomBubble')), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(c.summary.savedMinor, 2700);
      await tester.pump(const Duration(seconds: 4));
      expect(find.byKey(const Key('pigRoomBubble')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
