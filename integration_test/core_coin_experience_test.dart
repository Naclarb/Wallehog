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
  testWidgets('Android真实SQLite输入2、200与连续投币', (tester) async {
    // 独立测试数据库，不接触普通应用记录；每次使用新文件。
    final path =
        '${await getDatabasesPath()}/coin_${DateTime.now().microsecondsSinceEpoch}.db';
    final repo = await SqliteRecordRepository.open(databasePath: path);
    final c = RecordsController(repo);
    await c.load();
    await c.createGoal('PS5', 40000, style: 'ps5');
    await tester.pumpWidget(WallehogApp(controller: c));
    await tester.pumpAndSettle();
    Future<void> pause(int ms) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: ms)),
      );
      await tester.pump();
    }

    await pause(1500);
    var total = 0;
    var count = 0;
    for (final digits in ['2', '200', '2']) {
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await pause(350);
      for (final digit in digits.split('')) {
        await tester.tap(find.byKey(Key('key_$digit')));
        await tester.pump();
        await pause(250);
      }
      await pause(450);
      await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pump();
      await pause(1600);
      total += int.parse(digits) * 100;
      count++;
      expect(c.summary.savedMinor, total);
      expect(c.goalProgressMinor, total);
      expect(c.summary.goodChoices, count);
      await pause(500);
    }
    await pause(1200);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await repo.close();
  });
}
