import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/design_tokens.dart';
import 'package:wallehog/app/language_controller.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/data/backup_files.dart';
import 'package:wallehog/domain/backup.dart';
import '../support/memory_repository.dart';
import 'backup_flow_test.dart' show BackupMemoryRepository;

void main() {
  var stored = 'zh_CN';
  var allowSave = true;
  final writes = <String>[];

  setUp(() {
    stored = 'zh_CN';
    allowSave = true;
    writes.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LanguageController.channel, (call) async {
          if (call.method == 'getLanguage') return stored;
          if (call.method == 'setLanguage') {
            writes.add(call.arguments as String);
            if (allowSave) stored = call.arguments as String;
            return allowSave;
          }
          throw PlatformException(code: 'unexpected');
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LanguageController.channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(BackupFiles.channel, null);
  });

  Future<RecordsController> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    MemoryRepository? repository,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = RecordsController(repository ?? MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.createGoal('我的心愿', 100000);
    final now = DateTime.now();
    for (final amount in [12345, 567]) {
      await controller.save(
        SavingRecord(
          kind: DecisionKind.quick,
          description: '用户备注 $amount',
          amountMinor: amount,
          occurredOn: dateKey(now),
          createdAt: now,
          updatedAt: now,
          today: now,
        ),
      );
    }
    await tester.pumpWidget(WallehogApp(controller: controller));
    await tester.pumpAndSettle();
    return controller;
  }

  Future<void> choose(WidgetTester tester, String language) async {
    await tester.tap(find.byKey(const Key('helpTab')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('languageEntry')));
    await tester.tap(find.byKey(const Key('languageEntry')));
    await tester.pumpAndSettle();
    expect(find.text('简体中文'), findsWidgets);
    expect(find.text('English'), findsWidgets);
    await tester.tap(find.byKey(Key('language_$language')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'switch both ways, preserve every record and restore language after restart',
    (tester) async {
      final c = await open(tester);
      final snapshot = c.records.toList();
      final goal = c.goal;
      expect(find.text('+¥123.45'), findsOneWidget);
      await choose(tester, 'en');
      expect(find.byKey(const Key('helpPage')), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Sound effects'), findsOneWidget);
      await tester.tap(find.text('Records'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Drag the top handle'), findsOneWidget);
      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      expect(find.text(r'$129.12'), findsOneWidget);
      expect(find.text(r'$129.12 / $1000.00'), findsOneWidget);
      for (final amount in [r'+$123.45', r'+$5.67']) {
        final text = tester.widget<Text>(find.text(amount));
        expect(text.style!.color, positiveGreen);
      }
      expect(find.text('我的心愿'), findsOneWidget);
      expect(find.text('用户备注 12345'), findsOneWidget);
      expect(c.records, orderedEquals(snapshot));
      expect(c.goal, same(goal));
      expect(c.summary.savedMinor, 12912);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.text(r'$129.12'), findsOneWidget);

      await choose(tester, 'zh');
      expect(find.text('帮助'), findsOneWidget);
      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      for (final amount in ['+¥123.45', '+¥5.67']) {
        final text = tester.widget<Text>(find.text(amount));
        expect(text.style!.color, const Color(0xFFB83F4E));
      }
      expect(c.records, orderedEquals(snapshot));
      expect(writes, ['en', 'zh_CN']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed preference write keeps Chinese and allows retry', (
    tester,
  ) async {
    await open(tester);
    allowSave = false;
    await choose(tester, 'en');
    expect(find.byKey(const Key('language_en')), findsOneWidget);
    expect(find.text('语言设置保存失败，请重试。'), findsOneWidget);
    expect(
      find.byKey(const Key('languageSaveError')).hitTestable(),
      findsOneWidget,
    );
    expect(stored, 'zh_CN');
    allowSave = true;
    await tester.tap(find.byKey(const Key('language_en')));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(stored, 'en');
  });

  testWidgets(
    'English entry, validation and save use the same integer amounts',
    (tester) async {
      stored = 'en';
      final c = await open(tester);
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      expect(find.text(r'$0.00'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('expression')), '1/0');
      await tester.pump();
      expect(find.text('Cannot divide by zero.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('expression')), '(20+10)/2');
      await tester.pump();
      expect(find.text(r'+$15.00'), findsOneWidget);
      await tester.tap(find.byKey(const Key('advancedDetails')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('optionalNote')))
            .decoration!
            .hintText,
        'Note',
      );
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(c.summary.savedMinor, 14412);
      expect(c.records.first.savedMinor, 1500);
      expect(find.text(r'+$15.00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English backup preview and export keep CNY data and user text', (
    tester,
  ) async {
    stored = 'en';
    final c = await open(tester, repository: BackupMemoryRepository());
    final source = SavingsBackup.create(
      records: c.records,
      goals: c.goals,
      goal: c.goal,
      highWater: 2,
      exportedAt: DateTime.now(),
    ).encode();
    String? exported;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(BackupFiles.channel, (call) async {
          if (call.method == 'open') return source;
          exported = (call.arguments as Map)['content'] as String;
          return true;
        });
    await tester.tap(find.byKey(const Key('helpTab')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('backupEntry')), 200);
    await tester.tap(find.byKey(const Key('backupEntry')));
    await tester.pumpAndSettle();
    expect(find.text('Backup & restore'), findsOneWidget);
    expect(find.byTooltip('Export current data'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exportBackup')));
    await tester.pumpAndSettle();
    expect(SavingsBackup.decode(exported!).summary.savedMinor, 12912);
    expect(exported, contains('CNY'));
    await tester.tap(find.byKey(const Key('openBackup')));
    await tester.pumpAndSettle();
    expect(find.text('Restore preview'), findsOneWidget);
    expect(find.text(r'Total savings: $129.12'), findsOneWidget);
    expect(find.textContaining('Current wish: 我的心愿'), findsOneWidget);
    expect(c.summary.savedMinor, 12912);
    expect(tester.takeException(), isNull);
  });

  for (final (size, scale) in [
    (const Size(360, 800), 1.0),
    (const Size(390, 844), 2.0),
    (const Size(1219, 813), 1.0),
  ]) {
    testWidgets('English language sheet and forms fit $size at scale $scale', (
      tester,
    ) async {
      await open(tester, size: size, scale: scale);
      await choose(tester, 'en');
      await tester.tap(find.byKey(const Key('languageEntry')));
      await tester.pumpAndSettle();
      expect(find.textContaining('no currency conversion'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editGoal')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Headphones'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
