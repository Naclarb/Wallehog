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
import 'package:wallehog/domain/pig_room_lines.dart';
import 'package:wallehog/features/entry/calculator_sheet.dart';
import 'growth_test.dart' as growth;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  growth.main();
  testWidgets('真机小猪屋：本地互动、全局录入、编辑删除、SQLite重开与五级门槛', (tester) async {
    final root = await getDatabasesPath();
    final file = '$root/integration_pig_room.db';
    await deleteDatabase(file);
    var repo = await SqliteRecordRepository.open(databasePath: file);
    var c = RecordsController(repo);
    final errorFile = File('$root/pig-room-errors.txt');
    if (errorFile.existsSync()) errorFile.deleteSync();
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      File('$root/pig-room-errors.txt').writeAsStringSync(
        '${details.exceptionAsString()}\n${details.stack}\n',
        mode: FileMode.append,
      );
      previousErrorHandler?.call(details);
    };
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

    Future<void> tap(String key) async {
      if (['homeTab', 'historyTab', 'helpTab', 'pigRoomTab'].contains(key) &&
          find.byType(BottomSheet).evaluate().isNotEmpty) {
        Navigator.of(tester.element(find.text('小猪的角落'))).pop();
        await tester.pumpAndSettle();
      }
      if (key == 'pigRoomTab' &&
          find.byKey(const Key('pigRoomTab')).evaluate().isEmpty) {
        await tester.tap(find.byKey(const Key('homeTab')));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    Future<void> screenshot(String name) async {
      final boundary =
          capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$root/pig-room-$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    Future<void> add(String amount) async {
      await tap('homeTab');
      await tap('newRecord');
      expect(find.byType(CalculatorSheet), findsOneWidget);
      await tester.enterText(find.byKey(const Key('expression')), amount);
      await tap('confirmSaving');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    try {
      await c.load();
      await mount();
      await tap('pigRoomTab');
      expect(find.text('Lv.1'), findsOneWidget);
      await screenshot('empty');
      final positions = <double>[];
      var sampling = true;
      void sample(Duration _) {
        final pig = find.byKey(const Key('roomPigBounce'));
        if (sampling && pig.evaluate().isNotEmpty) {
          positions.add(
            (pig.evaluate().single.widget as Transform).transform.storage[13],
          );
          tester.binding.addPostFrameCallback(sample);
        }
      }

      tester.binding.addPostFrameCallback(sample);
      await tester.tap(find.byKey(const Key('roomPig')));
      await tester.pumpAndSettle();
      sampling = false;
      if (MediaQuery.disableAnimationsOf(
        tester.element(find.byKey(const Key('roomPig'))),
      )) {
        expect(positions.every((y) => y == 0), isTrue);
      } else {
        expect(
          positions.any((y) => y < -1),
          isTrue,
          reason: '逐帧采样弹跳位置：$positions',
        );
      }
      expect(
        PigRoomLines.pats,
        contains(
          tester.widget<Text>(find.byKey(const Key('pigRoomBubble'))).data,
        ),
      );
      await tap('roomPig');

      expect(
        PigRoomLines.pats,
        contains(
          tester.widget<Text>(find.byKey(const Key('pigRoomBubble'))).data,
        ),
      );
      expect((await repo.readSnapshot()).records, isEmpty);
      expect(c.summary.goodChoices, 0);
      expect(c.summary.savedMinor, 0);
      await screenshot('talk');
      await add('2');
      expect(c.summary.savedMinor, 200);
      expect(c.summary.goodChoices, 1);
      await tap('pigRoomTab');
      expect(find.text('Lv.1'), findsOneWidget);
      await tap('historyTab');
      await add('3');
      expect(c.summary.savedMinor, 500);
      await tap('homeTab');
      await add('1');
      expect(c.summary.goodChoices, 3);
      await c.save(growth.quick(1));
      await tap('pigRoomTab');
      await add('1');
      await tap('pigRoomTab');
      expect(find.text('Lv.2'), findsOneWidget);
      await screenshot('lv2');
      await tap('historyTab');
      await tester.tap(find.text('编辑').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expression')), '999');
      await tap('confirmSaving');
      expect(c.summary.goodChoices, 5);
      await tap('pigRoomTab');
      expect(find.text('Lv.2'), findsOneWidget);
      await tap('historyTab');
      await tester.tap(find.text('删除').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '删除').last);
      await tester.pumpAndSettle();
      expect(c.summary.goodChoices, 4);
      await tap('pigRoomTab');
      expect(find.text('Lv.1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await repo.close();
      repo = await SqliteRecordRepository.open(databasePath: file);
      c = RecordsController(repo);
      await c.load();
      await mount();
      await tap('pigRoomTab');
      expect(c.summary.goodChoices, 4);
      expect(find.text('Lv.1'), findsOneWidget);
      for (final entry in {
        5: 2,
        14: 2,
        15: 3,
        29: 3,
        30: 4,
        59: 4,
        60: 5,
      }.entries) {
        while (c.summary.goodChoices < entry.key) {
          await c.save(growth.quick(1));
        }
        await tester.pumpAndSettle();
        expect(find.text('Lv.${entry.value}'), findsOneWidget);
      }
      expect(find.text('Lv.5'), findsOneWidget);
      await screenshot('lv5');
      expect(tester.takeException(), isNull);
    } catch (error, stack) {
      File(
        '$root/pig-room-errors.txt',
      ).writeAsStringSync('$error\n$stack\n', mode: FileMode.append);
      rethrow;
    } finally {
      FlutterError.onError = previousErrorHandler;
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      await repo.close();
      await deleteDatabase(file);
    }
  });
}
