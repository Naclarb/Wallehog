import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/shared/pig_character.dart';
import 'package:wallehog/shared/inline_pig.dart';
import '../support/memory_repository.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(900, 700),
  ]) {
    testWidgets('$size 金币进入原猪真实投币口，小额大额同等计次', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = RecordsController(MemoryRepository());
      addTearDown(c.dispose);
      await c.load();
      await c.createGoal('PS5', 40000, style: 'ps5');
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      var total = 0;
      for (final amount in [2, 200, 2]) {
        await tester.tap(find.byKey(const Key('newRecord')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('expression')), '$amount');
        await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirmSaving')));
        await tester.tap(
          find.byKey(const Key('confirmSaving')),
          warnIfMissed: false,
        );
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
        await tester.pump(const Duration(milliseconds: 500));
        total += amount * 100;
        expect(c.summary.savedMinor, total);
        expect(c.goalProgressMinor, total);
        expect(
          c.summary.goodChoices,
          total == 200
              ? 1
              : total == 20200
              ? 2
              : 3,
        );
        final image = find.descendant(
          of: find.byType(InlinePig),
          matching: find.byType(PigCharacterView),
        );
        final rect = tester.getRect(image);
        final fitted = applyBoxFit(
          BoxFit.contain,
          PigCharacter.canvasSize,
          rect.size,
        ).destination;
        final slot =
            rect.topLeft +
            Offset(
              (rect.width - fitted.width) / 2,
              (rect.height - fitted.height) / 2,
            ) +
            Offset(
              fitted.width * PigCharacter.slot.dx,
              fitted.height * PigCharacter.slot.dy,
            );
        final coin = tester.getCenter(find.byKey(const Key('depositCoin')));
        expect((coin - slot).distance, lessThan(8));
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.byKey(const Key('depositCoin')), findsNothing);
        expect(tester.takeException(), isNull);
        // 不等待上一笔 1.4 秒动作/提示结束，立即继续保存。
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('播放中开启减少动态效果立即隐藏金币并停止猪动作', (tester) async {
    final c = RecordsController(MemoryRepository());
    addTearDown(c.dispose);
    await c.load();
    await tester.pumpWidget(WallehogApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expression')), '2');
    await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pump();
    for (
      var frame = 0;
      frame < 60 && find.byKey(const Key('depositFeedback')).evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('depositCoin')), findsOneWidget);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(find.byKey(const Key('depositCoin')), findsNothing);
    expect(find.text('已记录 +¥2.00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
