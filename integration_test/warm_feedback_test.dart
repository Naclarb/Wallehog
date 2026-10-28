import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('Android完整投币流程与三心愿切换', (tester) async {
    final location = '${await getDatabasesPath()}/warm_feedback_acceptance.db';
    await deleteDatabase(location);
    final repo = await SqliteRecordRepository.open(databasePath: location);
    final c = RecordsController(repo);
    await c.load();
    await c.createGoal('心愿演示', 10000, style: 'ps5');
    await c.createGoal('耳机', 100000, style: 'headphones');
    await c.createGoal('相机', 500000, style: 'camera');
    await c.selectGoal(c.goals.first.id!);
    await tester.pumpWidget(WallehogApp(controller: c));
    await tester.pumpAndSettle();
    Future<void> pause(int ms) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: ms)),
      );
      await tester.pump();
    }

    await pause(1800);
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await pause(650);
    await tester.tap(find.byKey(const Key('key_2')));
    await tester.pump();
    await pause(450);
    await tester.tap(find.byKey(const Key('key_7')));
    await tester.pump();
    await pause(850);
    await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pump();
    await pause(180);
    expect(c.summary.savedMinor, 2700);
    expect(c.goalProgressMinor, 2700);
    await pause(1700);
    await tester.pumpAndSettle();
    expect(find.text('¥27.00'), findsOneWidget);
    await pause(1800);
    await tester.tap(find.byKey(const Key('nextGoalPreview')));
    await tester.pumpAndSettle();
    expect(c.goal!.style, 'headphones');
    await pause(900);
    await tester.drag(
      find.byKey(const Key('goalCarousel')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();
    expect(c.goal!.style, 'camera');
    await pause(900);
    await tester.drag(
      find.byKey(const Key('goalCarousel')),
      const Offset(650, 0),
    );
    await tester.pumpAndSettle();
    await pause(900);
    expect(c.goal!.style, 'ps5');
    expect(c.goalProgressMinor, 2700);
    for (final entry in [
      (['2', '3'], '心愿已经走过一半'),
      (['5', '0'], '心愿进度达成！'),
    ]) {
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await pause(500);
      for (final digit in entry.$1) {
        await tester.tap(find.byKey(Key('key_$digit')));
        await tester.pump();
        await pause(300);
      }
      await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pump();
      await pause(1300);
      expect(find.text(entry.$2), findsOneWidget);
      await pause(1700);
    }
    expect(c.goalProgressMinor, 10000);
    expect(c.summary.savedMinor, 10000);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await repo.close();
  });
}
