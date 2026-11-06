import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/features/entry/calculator_sheet.dart';

import '../support/memory_repository.dart';

void main() {
  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(800, 1200),
  ]) {
    testWidgets(
      'binding selection, cancellation and saving at $size with large text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repo = MemoryRepository();
        final c = RecordsController(repo);
        addTearDown(c.dispose);
        await c.load();
        await c.createGoal('A', 10000);
        final a = c.goal!.id!;
        await c.createGoal(List.filled(20, '长心愿').join(), 10000);
        final b = c.goal!.id!;
        await tester.pumpWidget(WallehogApp(controller: c));
        await tester.tap(find.byKey(const Key('newRecord')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('expression')), '12');
        await tester.tap(find.byKey(const Key('advancedDetails')));
        await tester.pumpAndSettle();
        final binding = find.byKey(const Key('wishBinding'));
        await reveal(tester, binding);
        await reveal(tester, binding);
        await tester.tap(binding);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('bindingOption_$a')));
        await tester.pumpAndSettle();
        expect(c.records, isEmpty);
        await reveal(tester, binding);
        await tester.tap(binding);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('取消'));
        await tester.pumpAndSettle();
        await reveal(tester, find.byKey(const Key('confirmSaving')));
        await tester.tap(find.byKey(const Key('confirmSaving')));
        await tester.pumpAndSettle();
        expect(c.goal!.id, b);
        expect(c.goals.first.progressMinor(c.records), 1200);
        expect(c.goalProgressMinor, 0);
        expect(c.summary.savedMinor, 1200);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'editing opens original binding and failed write retains selected binding',
    (tester) async {
      final repo = MemoryRepository();
      final c = RecordsController(repo);
      addTearDown(c.dispose);
      await c.load();
      await c.createGoal('A', 10000);
      final a = c.goal!.id!;
      final now = DateTime.now();
      await c.save(
        SavingRecord(
          kind: DecisionKind.quick,
          description: '',
          amountMinor: 1200,
          occurredOn: dateKey(now),
          createdAt: now,
          updatedAt: now,
          today: now,
        ),
      );
      await c.createGoal('B', 10000);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSheet(controller: c, record: c.records.single),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('advancedDetails')));
      await tester.pumpAndSettle();
      final binding = find.byKey(const Key('wishBinding'));
      await reveal(tester, binding);
      expect(
        find.descendant(of: binding, matching: find.text('A')),
        findsOneWidget,
      );
      await tester.tap(binding);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bindingOption_0')));
      await tester.pumpAndSettle();
      repo.fail = true;
      await reveal(tester, find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      await reveal(tester, binding);
      expect(
        find.descendant(of: binding, matching: find.text('未绑定')),
        findsOneWidget,
      );
      expect(repo.assignments.values.single, a);
      repo.fail = false;
      await reveal(tester, find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(repo.assignments, isEmpty);
      expect(c.summary.savedMinor, 1200);
    },
  );
}
