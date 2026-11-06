import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/data/backup_files.dart';
import 'package:wallehog/domain/backup.dart';
import 'package:wallehog/features/backup/backup_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('真机快速记录、Goal、编辑删除与重开一致性', (tester) async {
    final dbRoot = await getDatabasesPath();
    final dbPath = path.join(dbRoot, 'integration_quick_v2.db');
    await deleteDatabase(dbPath);
    var repository = await SqliteRecordRepository.open(databasePath: dbPath);
    var controller = RecordsController(repository);
    await controller.load();
    await controller.createGoal('一副喜欢的耳机', 100000);
    final captureKey = GlobalKey();
    Future<void> mount() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: WallehogApp(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> reveal(Finder finder) async {
      await tester.pumpAndSettle();
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      if (name == 'ui-home' || name == 'ui-no-goal') {
        final scrollable = find.descendant(
          of: find.byKey(const Key('homeScroll')),
          matching: find.byType(Scrollable),
        );
        tester.state<ScrollableState>(scrollable.first).position.jumpTo(0);
        await tester.pumpAndSettle();
      }
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        path.join(dbRoot, '$name.png'),
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    }

    await mount();
    await reveal(find.byKey(const Key('newRecord')));
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('key_2')));
    await tester.tap(find.byKey(const Key('key_7')));
    await tester.pumpAndSettle();
    await reveal(find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(controller.summary.savedMinor, 2700);
    expect(controller.goalProgressMinor, 2700);
    expect(controller.summary.goodChoices, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.drag(
      find.byKey(const Key('homeScroll')),
      const Offset(0, 2000),
    );
    await tester.pumpAndSettle();
    await capture('ui-home');
    await tester.tap(find.byKey(const Key('pigRoomTab')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byKey(const Key('roomPig')));
    await tester.pumpAndSettle();
    expect(controller.summary.savedMinor, 2700);
    expect(controller.summary.goodChoices, 1);
    await capture('ui-pig-corner');
    expect(find.byKey(const Key('newRecord')), findsOneWidget);
    await tester.tap(find.byKey(const Key('helpTab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('newRecord')), findsNothing);
    expect(find.byKey(const Key('helpPage')), findsOneWidget);
    await capture('ui-help');
    await tester.tap(find.byKey(const Key('homeTab')));
    await tester.pumpAndSettle();
    await reveal(find.byKey(const Key('newRecord')));
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expression')), '30-12-10-5');
    await tester.pumpAndSettle();
    expect(find.text('+¥3.00'), findsOneWidget);
    await capture('ui-calculator');
    await reveal(find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(controller.summary.savedMinor, 3000);
    expect(controller.goalProgressMinor, 3000);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await repository.close();
    repository = await SqliteRecordRepository.open(databasePath: dbPath);
    controller = RecordsController(repository);
    await controller.load();
    expect(controller.goalProgressMinor, 3000);
    expect(controller.summary.goodChoices, 2);
    await mount();
    await reveal(find.text('全部记录  ›'));
    await tester.tap(find.text('全部记录  ›'));
    await tester.pumpAndSettle();
    await capture('ui-history');
    await tester.tap(find.text('编辑').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expression')), '2');
    await reveal(find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(controller.summary.savedMinor, 2900);
    expect(controller.goalProgressMinor, 2900);
    await tester.tap(find.text('删除').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '删除').last);
    await tester.pumpAndSettle();
    expect(controller.goalProgressMinor, 2700);
    expect(controller.summary.goodChoices, 1);
    await controller.clearGoal();
    await tester.tap(find.byKey(const Key('homeTab')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('homeScroll')),
      const Offset(0, 2000),
    );
    await tester.pumpAndSettle();
    await capture('ui-no-goal');
    await controller.createGoal('新心愿', 20000);
    expect(controller.goalProgressMinor, 0);
    // 在独立数据库中验证真实 Android SQLite 的备份往返；不接触日常应用。
    final backup = SavingsBackup.decode(
      (await repository.exportBackup()).encode(),
    );
    await controller.clearGoal();
    await controller.delete(controller.records.single.id!);
    expect(await controller.restoreBackup(backup), isTrue);
    expect(controller.summary.savedMinor, 2700);
    expect(controller.goal!.name, '新心愿');
    expect(controller.goalProgressMinor, 0);
    await mount();
    await tester.tap(find.byKey(const Key('helpTab')));
    await tester.pumpAndSettle();
    await capture('ui-corner');
    await tester.scrollUntilVisible(
      find.byKey(const Key('backupEntry')),
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('helpPage')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('备份与恢复'));
    await tester.pumpAndSettle();
    await capture('ui-backup');
    // 文件选择器交互单独人工验收；这里只替代文件读取，验证真实设备预览布局。
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      BackupFiles.channel,
      (call) async => call.method == 'open' ? backup.encode() : true,
    );
    await tester.tap(find.byKey(const Key('openBackup')));
    await tester.pumpAndSettle();
    await reveal(find.text('恢复预览'));
    await capture('ui-backup-preview');
    expect(controller.records.length, 1);
    expect(find.text('恢复预览'), findsOneWidget);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      BackupFiles.channel,
      null,
    );
    Navigator.of(tester.element(find.byType(BackupPage))).pop();
    await tester.pumpAndSettle();
    await controller.editGoal('新心愿', 1);
    // 当前目标起点后尚无记录，编辑目标不会将历史金额算进来。
    expect(controller.goalProgressMinor, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await repository.close();
    await deleteDatabase(dbPath);
  });
}
