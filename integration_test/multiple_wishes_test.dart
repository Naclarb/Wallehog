import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/domain/backup.dart';
import 'records_test.dart' as records;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  records.main();
  testWidgets('真机多心愿层叠切换、唯一归属、重启与备份往返', (tester) async {
    final root = await getDatabasesPath();
    final location = '$root/integration_multi_wishes.db';
    await deleteDatabase(location);
    var repo = await SqliteRecordRepository.open(databasePath: location);
    var c = RecordsController(repo);
    final capture = GlobalKey();
    Future<void> mount() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: WallehogApp(controller: c),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> save(int amount) async {
      final now = DateTime.now();
      expect(
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
        ),
        isTrue,
      );
    }

    Future<void> screenshot(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$root/multi-$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    try {
      await c.load();
      await c.createGoal('PS5', 400000, style: 'ps5');
      await save(280000);
      final ps5 = c.goal!.id!;
      await c.createGoal('一副好耳机', 100000, style: 'headphones');
      await save(5400);
      await c.createGoal('我的相机', 600000, style: 'camera');
      await c.selectGoal(ps5);
      await mount();
      await screenshot('ps5');
      await tester.drag(
        find.byKey(const Key('goalCarousel')),
        const Offset(-340, 0),
      );
      await tester.pumpAndSettle();
      expect(c.goal!.style, 'headphones');
      expect(c.goalProgressMinor, 5400);
      await screenshot('headphones');
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expression')), '2');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(c.goalProgressMinor, 5600);
      expect(c.goals.first.progressMinor(c.records), 280000);
      expect(c.summary.savedMinor, 285600);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nextGoal')));
      await tester.pumpAndSettle();
      expect(c.goal!.style, 'camera');
      await screenshot('camera');
      await tester.tap(find.byKey(const Key('addGoal')));
      await tester.pumpAndSettle();
      await screenshot('styles');
      Navigator.of(
        tester.element(find.byKey(const Key('goalNameInput'))),
      ).pop();
      await tester.pumpAndSettle();
      final backup = SavingsBackup.decode((await c.exportBackup()).encode());
      await c.clearGoal();
      expect(c.goals.length, 2);
      expect(c.summary.savedMinor, 285600);
      expect(await c.restoreBackup(backup), isTrue);
      expect(c.goals.length, 3);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await repo.close();
      repo = await SqliteRecordRepository.open(databasePath: location);
      c = RecordsController(repo);
      await c.load();
      expect(c.goal!.style, 'camera');
      expect(c.goalProgressMinor, 0);
      await c.selectGoal(ps5);
      expect(c.goalProgressMinor, 280000);
      await mount();
      await screenshot('ps5-three');
      await tester.tap(find.byKey(const Key('pigRoomTab')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byKey(const Key('pigRoomBubble')), findsOneWidget);
      await screenshot('pig');
      expect(c.summary.savedMinor, 285600);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await repo.close();
    }
  });
}
