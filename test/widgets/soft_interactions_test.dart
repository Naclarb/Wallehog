import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/features/entry/calculator_sheet.dart';
import '../support/memory_repository.dart';
import 'package:wallehog/shared/pig_character.dart';
import 'package:wallehog/character/pig_actor.dart';

Future<RecordsController> setup(
  WidgetTester tester,
  MemoryRepository repository, {
  double scale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final c = RecordsController(repository);
  addTearDown(c.dispose);
  await c.load();
  await c.createGoal('耳机', 100000);
  final now = DateTime.now();
  for (var i = 0; i < 2; i++) {
    await c.save(
      SavingRecord(
        kind: DecisionKind.quick,
        description: '记录$i',
        amountMinor: 1000,
        occurredOn: dateKey(now),
        createdAt: now,
        updatedAt: now,
        today: now,
      ),
    );
  }
  await tester.pumpWidget(WallehogApp(controller: c));
  await tester.pumpAndSettle();
  return c;
}

Future<void> showRow(WidgetTester tester, int id) async {
  await tester.ensureVisible(find.byKey(ValueKey('swipeSaving_$id')));
  await tester.pumpAndSettle();
}

double offset(WidgetTester tester, int id) => tester
    .widget<AnimatedContainer>(find.byKey(ValueKey('savingOffset_$id')))
    .transform!
    .storage[12];

void main() {
  testWidgets('右滑半行只露出删除，取消不写入，确认后汇总一致', (tester) async {
    final c = await setup(tester, MemoryRepository());
    final id = c.records.first.id!;
    await showRow(tester, id);
    final row = find.byKey(ValueKey('swipeSaving_$id'));
    await tester.drag(row, const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(offset(tester, id), tester.getSize(row).width / 2);
    expect(c.records.length, 2);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    await tester.tap(find.byKey(ValueKey('deleteSaving_$id')));
    await tester.pumpAndSettle();
    expect(find.text('删除这笔记录？'), findsOneWidget);
    await tester.tap(find.byTooltip('取消'));
    await tester.pumpAndSettle();
    expect(c.records.length, 2);
    await tester.drag(row, const Offset(200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('deleteSaving_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteSaving')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final pig = tester.widget<PigCharacterView>(
      find.byType(PigCharacterView).first,
    );
    expect(pig.action, PigAction.flyaway);
    await tester.pumpAndSettle();
    expect(c.records.length, 1);
    expect(c.summary.savedMinor, 1000);
    expect(c.goalProgressMinor, 1000);
    expect(c.summary.goodChoices, 1);
    expect(find.byKey(const Key('depositFeedback')), findsNothing);
    expect(find.byKey(const Key('depositCoin')), findsNothing);
  });

  testWidgets('轻触不编辑、长按进入原记录计算器并保留归属', (tester) async {
    final c = await setup(tester, MemoryRepository());
    final id = c.records.first.id!;
    await showRow(tester, id);
    final row = find.byKey(ValueKey('swipeSaving_$id'));
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(CalculatorSheet), findsNothing);
    await tester.longPress(row);
    await tester.pumpAndSettle();
    expect(
      tester.widget<CalculatorSheet>(find.byType(CalculatorSheet)).record!.id,
      id,
    );
    await tester.enterText(find.byKey(const Key('expression')), '12');
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(c.records.length, 2);
    expect(c.summary.savedMinor, 2200);
    expect(c.goalProgressMinor, 2200);
    expect(c.summary.goodChoices, 2);
    expect(find.byKey(const Key('depositFeedback')), findsNothing);
    expect(find.byKey(const Key('depositCoin')), findsNothing);
  });

  testWidgets('小幅拖动回弹、左滑收起、同时只展开一条、删除失败保留记录', (tester) async {
    final repo = MemoryRepository();
    final c = await setup(tester, repo);
    final first = c.records.first.id!;
    final second = c.records.last.id!;
    await showRow(tester, second);
    final row = find.byKey(ValueKey('swipeSaving_$first'));
    await tester.timedDrag(
      row,
      const Offset(50, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(offset(tester, first), 0);
    await tester.drag(row, const Offset(200, 0));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(ValueKey('swipeSaving_$second')),
      const Offset(200, 0),
    );
    await tester.pumpAndSettle();
    expect(offset(tester, first), 0);
    await tester.drag(
      find.byKey(ValueKey('swipeSaving_$second')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    expect(offset(tester, second), 0);
    await tester.drag(row, const Offset(200, 0));
    await tester.pumpAndSettle();
    repo.fail = true;
    await tester.tap(find.byKey(ValueKey('deleteSaving_$first')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteSaving')));
    await tester.pumpAndSettle();
    expect(c.records.length, 2);
    expect(c.summary.savedMinor, 2000);
    expect(c.error, isNotNull);
  });

  testWidgets('减少动画时右滑立即停半行，纵向浏览不展开记录', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final c = await setup(tester, MemoryRepository());
    final id = c.records.first.id!;
    await showRow(tester, id);
    final row = find.byKey(ValueKey('swipeSaving_$id'));
    await tester.drag(row, const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(offset(tester, id), 0);
    await tester.drag(row, const Offset(200, 0));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedContainer>(find.byKey(ValueKey('savingOffset_$id')))
          .duration,
      Duration.zero,
    );
    expect(offset(tester, id), tester.getSize(row).width / 2);
    expect(c.records.length, 2);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('柔和心愿弹窗窄屏字号 $scale 可保存且不显示重复说明', (tester) async {
      final c = await setup(
        tester,
        MemoryRepository(),
        scale: scale,
        size: const Size(360, 800),
      );
      await tester.ensureVisible(find.byKey(const Key('editGoal')));
      await tester.tap(find.byKey(const Key('editGoal')));
      await tester.pumpAndSettle();
      expect(find.text('选择心愿样式'), findsNothing);
      expect(find.text('保存心愿'), findsNothing);
      expect(find.byTooltip('保存心愿'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('goalNameInput')), '柔软的新心愿');
      await tester.enterText(find.byKey(const Key('goalTargetInput')), '2000');
      await tester.ensureVisible(find.byKey(const Key('saveGoal')));
      await tester.tap(find.byKey(const Key('saveGoal')));
      await tester.pumpAndSettle();
      expect(c.goal!.name, '柔软的新心愿');
      expect(c.goal!.targetMinor, 200000);
      expect(tester.takeException(), isNull);
    });
  }
}
