import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';
import '../test/support/fault_injecting_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android手机视口：提交后恢复、编辑安全重试、日期回退重开', (tester) async {
    // 仅运行于独立 .uitest 包，使用专用临时库，不触碰日常 wallehog.db。
    final dbPath = path.join(
      await getDatabasesPath(),
      'reliability_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    final stageLog = File(
      path.join(await getDatabasesPath(), 'reliability-stage.log'),
    );
    void mark(String stage) => stageLog.writeAsStringSync(
      '$stage\n',
      mode: FileMode.append,
      flush: true,
    );
    stageLog.writeAsStringSync('开始\n');
    var clock = DateTime.now();
    var db = await SqliteRecordRepository.open(
      databasePath: dbPath,
      clock: () => clock,
    );
    var repo = FaultInjectingRepository(db);
    var c = RecordsController(repo);
    try {
      await c.load();
      await c.createGoal('原心愿', 10000);
      final now = clock;
      await c.save(
        SavingRecord(
          kind: DecisionKind.forgone,
          description: '原记录',
          occurredOn: dateKey(now),
          createdAt: now,
          updatedAt: now,
          today: now,
        ),
      );
      final original = c.records.single;
      final backup = await c.exportBackup();
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addGoal')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('goalNameInput')), '新心愿');
      await tester.enterText(find.byKey(const Key('goalTargetInput')), '200');
      repo.failSnapshotAfterWrite = true;
      await tester.ensureVisible(find.byKey(const Key('saveGoal')));
      await tester.tap(find.byKey(const Key('saveGoal')));
      await tester.pumpAndSettle();
      expect(c.needsRecovery, isTrue);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(find.byKey(const Key('newRecord'))).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('helpTab')));
      await tester.pumpAndSettle();
      final attempts = Map.of(repo.attempts);
      expect(await c.clearGoal(), isFalse);
      expect(repo.attempts, attempts);
      await tester.tap(find.text('重新读取'));
      await tester.pumpAndSettle();
      expect(c.needsRecovery, isTrue);
      repo.failSnapshot = false;
      repo.failSnapshotAfterWrite = false;
      await tester.tap(find.text('重新读取'));
      await tester.pumpAndSettle();
      expect(c.goal!.name, '新心愿');
      expect(repo.attempts, attempts);
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expression')), '2');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(c.goalProgressMinor, 200);
      expect(c.summary.goodChoices, 2);
      mark('新心愿恢复和录入完成');

      await tester.tap(find.byKey(const Key('homeTab')));
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey('swipeSaving_${original.id}'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('description')), '失败后保留的内容');
      repo.failBeforeWrite = true;
      await tester.ensureVisible(find.byKey(const Key('saveRecord')));
      await tester.tap(find.byKey(const Key('saveRecord')));
      await tester.pumpAndSettle();
      expect(find.text('失败后保留的内容'), findsOneWidget);
      expect(c.needsRecovery, isFalse);
      repo.failBeforeWrite = false;
      await tester.tap(find.byKey(const Key('saveRecord')));
      await tester.pumpAndSettle();
      expect(
        c.records.singleWhere((r) => r.id == original.id).description,
        '失败后保留的内容',
      );
      expect(c.goalProgressMinor, 200);
      mark('未提交编辑重试完成');

      // 等原生键盘退场再定位实际文字，避免行中心在视口变化中偏移。
      FocusManager.instance.primaryFocus?.unfocus();
      for (var i = 0; i < 40 && tester.view.viewInsets.bottom > 0; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.view.viewInsets.bottom, 0);
      final editedRowText = find.text('失败后保留的内容');
      await tester.ensureVisible(editedRowText);
      await tester.pumpAndSettle();
      await tester.longPress(editedRowText);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('description')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('description')), '提交后的只读恢复');
      repo.failSnapshotAfterWrite = true;
      await tester.ensureVisible(find.byKey(const Key('saveRecord')));
      await tester.tap(find.byKey(const Key('saveRecord')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byKey(const Key('description'))).enabled,
        isFalse,
      );
      final editWrites = repo.commits['save'];
      repo.failSnapshot = false;
      repo.failSnapshotAfterWrite = false;
      await tester.tap(find.text('重新读取并返回，确认记录后再继续'));
      await tester.pumpAndSettle();
      expect(repo.commits['save'], editWrites);
      expect(
        c.records.singleWhere((r) => r.id == original.id).description,
        '提交后的只读恢复',
      );
      mark('已提交编辑重读完成');

      // 恢复事务提交后快照失败：恢复锁不允许再次恢复或提交其他业务写入。
      repo.failSnapshotAfterWrite = true;
      expect(await c.restoreBackup(backup), isFalse);
      expect(c.needsRecovery, isTrue);
      final restores = repo.attempts['restoreBackup'];
      expect(await c.restoreBackup(backup), isFalse);
      expect(repo.attempts['restoreBackup'], restores);
      repo.failSnapshot = false;
      repo.failSnapshotAfterWrite = false;
      expect(await c.load(), isTrue);
      expect(c.records.single.id, original.id);
      expect(c.goal!.name, '原心愿');
      mark('备份恢复完成');

      // 不改系统时间：注入仓储时钟，验证真正的Android SQLite关闭重开。
      await tester.pumpWidget(const SizedBox.shrink());
      mark('重开前页面已移除');
      await tester.pumpAndSettle();
      mark('重开前页面已稳定');
      c.dispose();
      await db.close();
      mark('重开前数据库已关闭');
      clock = clock.subtract(const Duration(days: 370));
      db = await SqliteRecordRepository.open(
        databasePath: dbPath,
        clock: () => clock,
      );
      repo = FaultInjectingRepository(db);
      mark('回退日期数据库已重开');
      c = RecordsController(repo);
      expect(await c.load(), isTrue);
      mark('回退日期快照已读取');
      expect(c.records.single.occurredOn, original.occurredOn);
      expect(c.goal!.recordIds, {original.id});
      expect(c.summary.goodChoices, 1);
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      mark('最终页面已呈现');
      expect(find.byKey(const Key('savedMoney')), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      // 在仍由测试绑定驱动的平台消息循环中清理，避免异步 teardown 等待。
      mark('清理开始');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      c.dispose();
      await db.close();
      await deleteDatabase(dbPath);
      mark('清理完成');
    }
  });
}
