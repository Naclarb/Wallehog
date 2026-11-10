import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import '../support/memory_repository.dart';
import 'package:wallehog/domain/backup.dart';

void main() {
  for (final style in ['travel', 'sport', 'learning', 'home']) {
    testWidgets('new representative wish $style preserves a custom name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = RecordsController(MemoryRepository());
      addTearDown(controller.dispose);
      await controller.load();
      await controller.createGoal('Existing wish', 10000);
      await tester.pumpWidget(WallehogApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('addGoal')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('goalNameInput')),
        'My personal wish',
      );
      await tester.tap(find.byKey(Key('style_$style')));
      await tester.enterText(find.byKey(const Key('goalTargetInput')), '1000');
      await tester.ensureVisible(find.byKey(const Key('saveGoal')));
      await tester.tap(find.byKey(const Key('saveGoal')));
      await tester.pumpAndSettle();
      expect(controller.goal!.style, style);
      expect(controller.goal!.name, 'My personal wish');
      final backup = SavingsBackup.decode(
        SavingsBackup.create(
          records: controller.records,
          goal: controller.goal,
          highWater: 0,
          exportedAt: DateTime.now(),
        ).encode(),
      );
      expect(backup.goals.single.style, style);
      expect(tester.takeException(), isNull);
    });
  }
}
