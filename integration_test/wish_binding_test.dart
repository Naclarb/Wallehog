import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/app/language_controller.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/domain/backup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native wish adoption, image binding, edit, restart and backup', (
    tester,
  ) async {
    final root = await getDatabasesPath();
    final location =
        '$root/wish-binding-${DateTime.now().microsecondsSinceEpoch}.db';
    var repo = await SqliteRecordRepository.open(databasePath: location);
    var c = RecordsController(repo);
    final language = LanguageController();
    await language.load();
    await language.select(LanguageController.chinese);
    final capture = GlobalKey();
    Future<void> mount() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: WallehogApp(controller: c, languageController: language),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> reveal(Finder finder) async {
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$root/wish-binding-$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    }

    Future<void> save(int amount, {bool unbound = false}) async {
      final now = DateTime.now();
      expect(
        await c.save(
          SavingRecord(
            kind: DecisionKind.quick,
            description: 'Native binding test',
            amountMinor: amount,
            occurredOn: dateKey(now),
            createdAt: now,
            updatedAt: now,
            today: now,
          ),
          updateGoal: unbound,
        ),
        isTrue,
      );
    }

    Future<void> details() async {
      await tester.tap(find.byKey(const Key('advancedDetails')));
      await reveal(find.byKey(const Key('wishBinding')));
    }

    try {
      await c.load();
      await save(1250);
      await save(750);
      await mount();
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('key_5')));
      await details();
      expect(find.text('未绑定'), findsNothing);
      await shot('unbound');
      await tester.tap(find.byKey(const Key('wishBinding')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bindingOption_0')), findsOneWidget);
      expect(find.byKey(const Key('bindingOption_1')), findsNothing);
      await tester.tap(find.byKey(const Key('bindingOption_0')));
      await reveal(find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(c.summary.savedMinor, 2500);
      expect(c.goal, isNull);
      await reveal(find.byKey(const Key('createGoal')));
      await tester.tap(find.byKey(const Key('createGoal')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('goalNameInput')))
            .decoration!
            .hintText,
        isNull,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('goalTargetInput')))
            .decoration!
            .hintText,
        isNull,
      );
      await shot('create');
      await tester.tap(find.byKey(const Key('style_headphones')));
      await tester.enterText(find.byKey(const Key('goalNameInput')), '耳机');
      await tester.enterText(find.byKey(const Key('goalTargetInput')), '100');
      await reveal(find.byKey(const Key('saveGoal')));
      await tester.tap(find.byKey(const Key('saveGoal')));
      await tester.pumpAndSettle();
      final a = c.goal!.id!;
      expect(c.goalProgressMinor, 2500);
      await save(300, unbound: true);
      expect(await c.createGoal('相机', 20000, style: 'camera'), isTrue);
      final b = c.goal!.id!;
      expect(c.goalProgressMinor, 0);
      await c.selectGoal(a);
      expect(c.goalProgressMinor, 2500);
      await c.selectGoal(b);
      expect(c.goalProgressMinor, 0);
      await mount();
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('key_2')));
      await details();
      await tester.tap(find.byKey(const Key('wishBinding')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('wishBindingPicker')),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(find.byKey(const Key('bindingOption_3')), findsNothing);
      await shot('picker');
      await tester.tap(find.byKey(Key('bindingOption_$a')));
      await reveal(find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(c.goalProgressMinor, 0);
      expect(c.goals.first.progressMinor(c.records), 2700);
      final old = c.records.firstWhere((r) => r.savedMinor == 1250);
      final row = find.byKey(ValueKey('swipeSaving_${old.id}'));
      await reveal(row);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await details();
      await tester.tap(find.byKey(const Key('wishBinding')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('bindingOption_$b')));
      await reveal(find.byKey(const Key('confirmSaving')));
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(c.goalProgressMinor, 1250);
      expect(c.goals.first.progressMinor(c.records), 1450);
      expect(c.summary.savedMinor, 3000);
      final ids = c.records.map((r) => r.id).toList();
      final backup = SavingsBackup.decode((await c.exportBackup()).encode());
      expect(await c.restoreBackup(backup), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await repo.close();
      repo = await SqliteRecordRepository.open(databasePath: location);
      c = RecordsController(repo);
      await c.load();
      expect(c.records.map((r) => r.id), orderedEquals(ids));
      expect(c.goalProgressMinor, 1250);
      expect(c.summary.savedMinor, 3000);
      await language.select(LanguageController.english);
      await mount();
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await details();
      expect(find.byTooltip('Linked wish'), findsOneWidget);
      await tester.tap(find.byKey(const Key('wishBinding')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Unbound'), findsOneWidget);
      await shot('english-picker');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      language.dispose();
      c.dispose();
      await repo.close();
    }
  });
}
