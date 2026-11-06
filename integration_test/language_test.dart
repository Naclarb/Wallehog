import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wallehog/app/design_tokens.dart';
import 'package:wallehog/app/language_controller.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native language preference, SQLite preservation and phone layout',
    (tester) async {
      final root = await getDatabasesPath();
      // Dedicated, new test data in the .uitest package; never the daily database.
      final repo = await SqliteRecordRepository.open(
        databasePath:
            '$root/language-${DateTime.now().microsecondsSinceEpoch}.db',
      );
      final c = RecordsController(repo);
      final language = LanguageController();
      await language.load();
      final original = language.locale;
      final capture = GlobalKey();
      await c.load();
      await c.createGoal('PS5', 400000, style: 'ps5');
      final now = DateTime.now();
      for (final amount in [1250, 3000]) {
        expect(
          await c.save(
            SavingRecord(
              kind: DecisionKind.quick,
              description: 'Device test $amount',
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
      final ids = c.records.map((r) => r.id).toList();
      Future<void> mount(LanguageController settings) async {
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: WallehogApp(controller: c, languageController: settings),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> screenshot(String name) async {
        final boundary =
            capture.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$root/language-native-$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }

      Future<void> select(String code) async {
        await tester.tap(find.byKey(const Key('helpTab')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('languageEntry')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('language_$code')));
        await tester.pumpAndSettle();
      }

      try {
        expect(await language.select(LanguageController.chinese), isTrue);
        await mount(language);
        await screenshot('zh-home');
        await select('en');
        expect(find.text('Language'), findsOneWidget);
        await screenshot('en-help');
        await tester.tap(find.byKey(const Key('homeTab')));
        await tester.pumpAndSettle();
        for (final amount in [r'+$12.50', r'+$30.00']) {
          expect(
            tester.widget<Text>(find.text(amount)).style!.color,
            positiveGreen,
          );
        }
        await screenshot('en-home');
        await tester.pumpWidget(const SizedBox.shrink());
        final reopened = LanguageController();
        await reopened.load();
        expect(reopened.locale, LanguageController.english);
        await mount(reopened);
        expect(find.text(r'$42.50'), findsOneWidget);
        await select('zh');
        expect(find.text('语言'), findsOneWidget);
        await tester.tap(find.byKey(const Key('homeTab')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.text('+¥12.50')).style!.color,
          const Color(0xFFB83F4E),
        );
        await c.load();
        expect(c.records.map((r) => r.id), orderedEquals(ids));
        expect(c.summary.savedMinor, 4250);
        await tester.pumpWidget(const SizedBox.shrink());
        reopened.dispose();
      } finally {
        final restore = LanguageController();
        await restore.load();
        await restore.select(original);
        restore.dispose();
        language.dispose();
        c.dispose();
        await repo.close();
      }
    },
  );
}
