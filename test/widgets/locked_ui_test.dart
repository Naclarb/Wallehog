import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/features/entry/calculator_sheet.dart';
import '../support/memory_repository.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(360, 800)]) {
    testWidgets('锁定首页 ${size.width}×${size.height}、固定导航与入口', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final controller = RecordsController(MemoryRepository());
      addTearDown(controller.dispose);
      await controller.load();
      await controller.createGoal('一副喜欢的耳机', 100000);
      final now = DateTime.now();
      await controller.save(
        SavingRecord(
          kind: DecisionKind.quick,
          description: '',
          amountMinor: 2700,
          occurredOn: dateKey(now),
          createdAt: now,
          updatedAt: now,
          today: now,
        ),
      );

      await tester.pumpWidget(WallehogApp(controller: controller));
      await tester.pumpAndSettle();
      final corner = tester.getRect(find.byKey(const Key('pigRoomTab')));
      expect(corner.top, lessThan(100));
      expect(corner.center.dx, greaterThan(size.width / 2));
      for (final name in ['goalCard', 'savedMoney', 'newRecord']) {
        final rect = tester.getRect(find.byKey(Key(name)));
        expect(rect.top, greaterThanOrEqualTo(24));
        expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
      }
      // 完整记录随首页滚动，不再要求整个列表位于首屏。
      expect(find.byKey(const Key('littleWins')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('goalItem'))).width, 128);
      expect(find.text('¥27.00 / ¥1000.00'), findsOneWidget);
      expect(find.textContaining('不代表'), findsNothing);
      expect(find.text('已积累 3%'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      final navTop = tester.getTopLeft(find.byKey(const Key('newRecord'))).dy;
      await tester.drag(
        find.byKey(const Key('homeScroll')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const Key('newRecord'))).dy, navTop);
      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('+¥27.00'));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(CalculatorSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('historyTab')), findsNothing);
      await tester.tap(find.byKey(const Key('helpTab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('helpPage')), findsOneWidget);
      await tester.tap(find.text('金额的含义'));
      await tester.pumpAndSettle();
      expect(find.textContaining('不代表真实存款'), findsOneWidget);
      expect(find.byKey(const Key('newRecord')).hitTestable(), findsOneWidget);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('备份'),
        250,
        scrollable: find.descendant(
          of: find.byKey(const Key('helpPage')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.takeException(), isNull);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorSheet), findsOneWidget);
      expect(find.text('这次省下多少？'), findsNothing);
      expect(find.textContaining('不代表'), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.enterText(find.byKey(const Key('expression')), '27');
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(CalculatorSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editGoal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clearGoal')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '取消').last);
      await tester.pumpAndSettle();
      expect(controller.goal, isNotNull);
      await tester.tap(find.byKey(const Key('clearGoal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmClearGoal')));
      await tester.pumpAndSettle();
      expect(controller.goal, isNull);
      expect(controller.summary.savedMinor, 2700);

      expect(tester.takeException(), isNull);
    });
  }
}
