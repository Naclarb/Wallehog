import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/features/entry/calculator_sheet.dart';
import '../support/memory_repository.dart';

void main() {
  for (final size in [
    const Size(600, 960),
    const Size(813, 1219),
    const Size(1219, 813),
    const Size(1024, 600),
  ]) {
    testWidgets('平板 $size 导航、记录与布局', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = RecordsController(MemoryRepository());
      addTearDown(controller.dispose);
      await controller.load();
      await controller.createGoal('一副喜欢的耳机', 100000);
      await tester.pumpWidget(WallehogApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(
        tester
            .widget<Scaffold>(find.byType(Scaffold).first)
            .bottomNavigationBar,
        isNull,
      );
      expect(
        find.byKey(const Key('tabletColumns')),
        size.width >= 1024 ? findsOneWidget : findsNothing,
      );
      expect(
        tester.getRect(find.byKey(const Key('goalCard'))).left,
        greaterThan(88),
      );
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorSheet), findsOneWidget);
      expect(
        tester.getSize(find.byType(CalculatorSheet)).width,
        lessThanOrEqualTo(480),
      );
      await tester.enterText(find.byKey(const Key('expression')), '27');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(controller.summary.savedMinor, 2700);
      expect(controller.goalProgressMinor, 2700);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('historyTab')), findsNothing);
      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(CalculatorSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('goalCard')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('窗口缩放与大字体保留目标和未提交输入', (tester) async {
    tester.view.physicalSize = const Size(1219, 813);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = RecordsController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.createGoal(List.filled(12, '喜欢的耳机').join(), 100000);
    await tester.pumpWidget(WallehogApp(controller: controller));
    await tester.pumpAndSettle();
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tabletColumns')), findsNothing);
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expression')), '27');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expression')))
          .controller!
          .text,
      '27',
    );
    Navigator.of(tester.element(find.byType(CalculatorSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    tester.view.physicalSize = const Size(600, 960);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    tester.view.physicalSize = const Size(599, 960);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsNothing);
    expect(controller.goal!.name.length, 60);
    expect(tester.takeException(), isNull);
  });
}
