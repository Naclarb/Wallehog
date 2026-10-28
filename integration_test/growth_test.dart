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
import 'package:wallehog/domain/pig_growth.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'records_test.dart' as records;

SavingRecord quick(int amount, {SavingRecord? previous}) {
  final now = DateTime.now();
  return SavingRecord(
    id: previous?.id,
    kind: DecisionKind.quick,
    description: '',
    amountMinor: amount,
    occurredOn: dateKey(now),
    createdAt: previous?.createdAt ?? now,
    updatedAt: now,
    today: now,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  records.main();
  testWidgets('真机成长全部门槛、编辑删除、重启与升级去重', (tester) async {
    final root = await getDatabasesPath();
    final file = '$root/integration_growth_v3.db';
    await deleteDatabase(file);
    var repo = await SqliteRecordRepository.open(databasePath: file);
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

    Future<void> screenshot(String name) async {
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$root/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    Future<void> add() async {
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expression')), '27');
      await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
    }

    try {
      await c.load();
      await c.createGoal('一副喜欢的耳机', 100000);
      for (final threshold in [5, 15, 30, 60]) {
        while (c.summary.goodChoices < threshold - 1) {
          await c.save(quick(1));
        }
        await mount();
        expect(find.byKey(const Key('levelUpCelebration')), findsNothing);
        await add();
        final level = PigGrowth(threshold).level;
        expect(c.summary.goodChoices, threshold);
        expect(find.text('升级啦！Lv.$level'), findsOneWidget);
        expect(find.byKey(const Key('levelUpCelebration')), findsOneWidget);
        await screenshot('growth-upgrade-lv$level');
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      }
      final latest = c.records.first;
      await c.save(quick(999999999, previous: latest));
      expect(c.summary.goodChoices, 60);
      expect(PigGrowth(c.summary.goodChoices).level, 5);
      await c.delete(latest.id!);
      expect(PigGrowth(c.summary.goodChoices).level, 4);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await repo.close();
      repo = await SqliteRecordRepository.open(databasePath: file);
      c = RecordsController(repo);
      await c.load();
      expect(c.summary.goodChoices, 59);
      await mount();
      expect(find.byKey(const Key('levelUpCelebration')), findsNothing);
      await add();
      expect(c.summary.goodChoices, 60);
      expect(find.text('Lv.5'), findsOneWidget);
      expect(find.byKey(const Key('levelUpCelebration')), findsNothing);
      await screenshot('growth-repeat-no-celebration');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pigRoomTab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('roomLevel')), findsOneWidget);
      expect(find.text('Lv.5'), findsOneWidget);
      await screenshot('growth-corner-lv5');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await repo.close();
      await deleteDatabase(file);
    }
  });
}
