import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/data/backup_files.dart';
import 'package:wallehog/domain/backup.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/features/backup/backup_page.dart';
import '../support/memory_repository.dart';

class BackupMemoryRepository extends MemoryRepository
    implements BackupRepository {
  int restores = 0;
  bool failAfterRestore = false;
  @override
  Future<SavingsBackup> exportBackup() async => SavingsBackup.create(
    records: records,
    goal: goal,
    goals: (await readSnapshot()).goals,
    highWater: highWater,
    exportedAt: DateTime.now(),
  );
  @override
  Future<void> restoreBackup(SavingsBackup backup) async {
    restores++;
    records
      ..clear()
      ..addAll(backup.records);
    goal = backup.goal;
    goals
      ..clear()
      ..addAll(backup.goals);
    assignments.clear();
    for (final g in backup.goals) {
      for (final id in g.recordIds!) {
        assignments[id] = g.id!;
      }
      if (g.id! > goalHighWater) goalHighWater = g.id!;
    }
    highWater = backup.highWater;
    failRead = failAfterRestore;
  }
}

void main() {
  late BackupMemoryRepository repo;
  late RecordsController controller;
  String? opened;
  bool saved = true;
  String? exported;
  setUp(() async {
    repo = BackupMemoryRepository();
    controller = RecordsController(repo);
    await controller.load();
    opened = null;
    exported = null;
    saved = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(BackupFiles.channel, (call) async {
          if (call.method == 'open') return opened;
          exported = (call.arguments as Map)['content'] as String;
          return saved;
        });
  });
  tearDown(() {
    controller.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(BackupFiles.channel, null);
  });
  Future<void> mount(WidgetTester tester) =>
      tester.pumpWidget(MaterialApp(home: BackupPage(controller: controller)));
  testWidgets('帮助直接打开备份，清除心愿提交后读失败只重读', (tester) async {
    await controller.createGoal('耳机', 200);
    await tester.pumpWidget(WallehogApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings')), findsNothing);
    await tester.tap(find.byKey(const Key('helpTab')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('backupEntry')),
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('helpPage')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backupEntry')));
    await tester.pumpAndSettle();
    expect(find.byType(BackupPage), findsOneWidget);
    Navigator.of(tester.element(find.byType(BackupPage))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('homeTab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editGoal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clearGoal')));
    await tester.pumpAndSettle();
    repo.failRead = true;
    await tester.tap(find.byKey(const Key('confirmClearGoal')));
    await tester.pumpAndSettle();
    expect(repo.goal, isNull);
    expect(find.byTooltip('重试读取'), findsOneWidget);
    repo.failRead = false;
    await tester.tap(find.byKey(const Key('saveGoal')));
    await tester.pumpAndSettle();
    expect(controller.goal, isNull);
    expect(find.byKey(const Key('saveGoal')), findsNothing);
  });
  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(Key(key));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('选择取消或损坏文件不修改数据，导出取消不报成功', (tester) async {
    await mount(tester);
    await tap(tester, 'openBackup');
    expect(find.text('已取消选择。'), findsOneWidget);
    opened = '{broken';
    await tap(tester, 'openBackup');
    expect(find.textContaining('备份格式无效'), findsOneWidget);
    expect(repo.restores, 0);
    saved = false;
    await tap(tester, 'exportBackup');
    expect(find.text('已取消导出。'), findsOneWidget);
    expect(SavingsBackup.decode(exported!).records, isEmpty);
  });
  testWidgets('预览和二次确认取消均不写入，确认才替换', (tester) async {
    opened = (await repo.exportBackup()).encode();
    await controller.createGoal('当前心愿', 1000);
    await mount(tester);
    await tap(tester, 'openBackup');
    expect(repo.restores, 0);
    await tap(tester, 'restoreBackup');
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(repo.restores, 0);
    expect(controller.goal!.name, '当前心愿');
    await tap(tester, 'restoreBackup');
    await tap(tester, 'confirmRestore');
    expect(repo.restores, 1);
    expect(controller.goal, isNull);
    expect(find.text('恢复完成，记录与心愿已更新。'), findsOneWidget);
  });
  testWidgets('恢复已提交但读取失败只重读，不重复恢复', (tester) async {
    opened = (await repo.exportBackup()).encode();
    repo.failAfterRestore = true;
    await mount(tester);
    await tap(tester, 'openBackup');
    await tap(tester, 'restoreBackup');
    await tap(tester, 'confirmRestore');
    expect(repo.restores, 1);
    repo.failRead = false;
    await tester.ensureVisible(find.text('重新读取'));
    await tester.tap(find.text('重新读取'));
    await tester.pumpAndSettle();
    expect(find.text('读取完成。'), findsOneWidget);
    expect(repo.restores, 1);
  });
  testWidgets('达到目标庆祝一次，重建不重复；删除后真实回退', (tester) async {
    await controller.createGoal('耳机', 200);
    await tester.pumpWidget(WallehogApp(controller: controller));
    await tester.pumpAndSettle();
    await tap(tester, 'newRecord');
    await tester.enterText(find.byKey(const Key('expression')), '2');
    await tester.pumpAndSettle();
    await tap(tester, 'confirmSaving');
    expect(find.byKey(const Key('depositFeedback')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(WallehogApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('心愿进度达成！每一个小选择，都算数 ♡'), findsNothing);
    expect(find.text('心愿进度已达成'), findsOneWidget);
    await controller.delete(controller.records.single.id!);
    await tester.pumpAndSettle();
    expect(find.text('已积累 0%'), findsOneWidget);
  });
  testWidgets('备份页面手机预览与双倍字体可滚动，无溢出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await controller.createGoal('一副喜欢的耳机', 100000);
    final now = DateTime.now();
    await controller.save(
      SavingRecord(
        kind: DecisionKind.quick,
        description: '今天自带午餐',
        amountMinor: 2700,
        occurredOn: dateKey(now),
        createdAt: now,
        updatedAt: now,
        today: now,
      ),
    );
    opened = (await repo.exportBackup()).encode();
    await mount(tester);
    await tester.pumpAndSettle();
    await tap(tester, 'openBackup');
    await tester.ensureVisible(find.text('恢复预览'));
    await tester.pumpAndSettle();
    expect(find.text('记录：1 笔'), findsOneWidget);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('restoreBackup')),
      200,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repo.restores, 0);
  });
}
