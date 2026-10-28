import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';
import '../support/fault_injecting_repository.dart';

SavingRecord draft({SavingRecord? original, int amount = 200}) {
  final now = DateTime.now();
  return SavingRecord(
    id: original?.id,
    kind: DecisionKind.quick,
    description: '保留的编辑',
    amountMinor: amount,
    clientToken: original?.clientToken ?? 'reliability-$amount',
    occurredOn: original?.occurredOn ?? dateKey(now),
    createdAt: original?.createdAt ?? now,
    updatedAt: now,
    today: now,
  );
}

void main() {
  sqfliteFfiInit();
  for (final operation in [
    '新增',
    '编辑',
    '删除',
    '创建心愿',
    '编辑心愿',
    '清除心愿',
    '切换心愿',
    '恢复备份',
  ]) {
    test('$operation 提交后读取失败：全局阻止写入，失败重读及最终恢复不重复提交', () async {
      final db = await SqliteRecordRepository.open(
        databasePath: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
      final repo = FaultInjectingRepository(db);
      final c = RecordsController(repo);
      addTearDown(() async {
        c.dispose();
        await db.close();
      });
      await c.load();
      await c.createGoal('A', 10000);
      final a = c.goal!.id!;
      await c.save(draft());
      final original = c.records.single;
      final backup = await c.exportBackup();
      await c.createGoal('B', 20000);
      final beforeCount = c.records.length;
      repo.failSnapshotAfterWrite = true;
      final success = await switch (operation) {
        '新增' => c.save(draft(amount: 300)),
        '编辑' => c.save(draft(original: original, amount: 400)),
        '删除' => c.delete(original.id!),
        '创建心愿' => c.createGoal('C', 30000),
        '编辑心愿' => c.editGoal('新的B', 25000),
        '清除心愿' => c.clearGoal(),
        '切换心愿' => c.selectGoal(a),
        _ => c.restoreBackup(backup),
      };
      expect(success, isFalse);
      expect(c.writeCommitted, isTrue);
      final committedSnapshot = await db.readSnapshot();
      expect(c.loaded, isFalse, reason: '不能继续把旧快照标成可用');
      expect(c.needsRecovery, isTrue);
      final attempts = Map.of(repo.attempts);
      final commits = Map.of(repo.commits);
      Future<void> assertBlocked() async {
        expect(await c.save(draft(amount: 500)), isFalse);
        expect(await c.delete(original.id!), isFalse);
        expect(await c.createGoal('不能创建', 100), isFalse);
        expect(await c.editGoal('不能修改', 100), isFalse);
        expect(await c.clearGoal(), isFalse);
        expect(await c.selectGoal(a), isFalse);
        expect(await c.restoreBackup(backup), isFalse);
        expect(repo.attempts, attempts);
      }

      await assertBlocked();
      expect(await c.load(), isFalse);
      expect(c.loaded, isFalse);
      expect(c.error, contains('读取'));
      await assertBlocked();
      repo.snapshotGate = Completer<void>();
      repo.failSnapshot = false;
      final recovery = c.load();
      expect(c.busy, isTrue);
      await assertBlocked();
      repo.snapshotGate!.complete();
      expect(await recovery, isTrue);
      expect(c.loaded, isTrue);
      expect(c.needsRecovery, isFalse);
      expect(c.error, isNull);
      expect(repo.commits, commits);
      expect(
        c.records.map((r) => (r.id, r.savedMinor)),
        committedSnapshot.records.map((r) => (r.id, r.savedMinor)),
      );
      expect(c.goal?.id, committedSnapshot.goal?.id);
      expect(
        c.goals.map((g) => (g.id, g.name, g.targetMinor)),
        committedSnapshot.goals.map((g) => (g.id, g.name, g.targetMinor)),
      );
      expect(
        c.summary.savedMinor,
        SavingsSummary.fromRecords(committedSnapshot.records).savedMinor,
      );
      expect(c.summary.goodChoices, committedSnapshot.records.length);
      expect(
        c.goalProgressMinor,
        committedSnapshot.goal?.progressMinor(committedSnapshot.records) ?? 0,
      );
      for (final g in c.goals) {
        expect(
          g.recordIds,
          committedSnapshot.goals
              .singleWhere((row) => row.id == g.id)
              .recordIds,
        );
      }
      if (operation == '新增') expect(c.records.length, beforeCount + 1);
      repo.failSnapshotAfterWrite = false;
      expect(await c.save(draft(amount: 600)), isTrue);
      final latest = await db.readSnapshot();
      if (latest.goal != null) {
        expect(latest.goal!.recordIds, contains(latest.records.first.id));
      }
    });
  }

  test('事务调用前失败可安全重试，编辑身份和归属保持，成功后重放token不重复', () async {
    final db = await SqliteRecordRepository.open(
      databasePath: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final repo = FaultInjectingRepository(db);
    final c = RecordsController(repo);
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    await c.load();
    await c.createGoal('原心愿', 10000);
    await c.save(draft());
    final original = c.records.single;
    final assignment = c.goal!.recordIds;
    final edited = draft(original: original, amount: 700);
    repo.failBeforeWrite = true;
    expect(await c.save(edited), isFalse);
    expect(c.writeCommitted, isFalse);
    expect(c.loaded, isTrue);
    expect((await db.readAll()).single.savedMinor, 200);
    repo.failBeforeWrite = false;
    expect(await c.save(edited), isTrue);
    expect(c.records.single.savedMinor, 700);
    expect(c.records.single.id, original.id);
    expect(c.goal!.recordIds, assignment);
    final added = draft(amount: 800);
    expect(await c.save(added), isTrue);
    expect(await c.save(added), isTrue);
    expect(c.records.length, 2);
    expect(c.summary.savedMinor, 1500);
  });

  test('SQLite事务中归属写入/删除失败会完整回滚，解除故障后安全重试', () async {
    final db = await SqliteRecordRepository.open(
      databasePath: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    final c = RecordsController(db);
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    await c.load();
    await c.createGoal('保留归属', 10000);
    final sql = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await sql.execute(
      "CREATE TRIGGER reject_assignment BEFORE INSERT ON goal_records BEGIN SELECT RAISE(ABORT, '注入事务中失败'); END",
    );
    expect(await c.save(draft()), isFalse);
    expect(c.writeCommitted, isFalse);
    expect(c.needsRecovery, isFalse);
    expect(await db.readAll(), isEmpty);
    expect(c.goal!.recordIds, isEmpty);
    await sql.execute('DROP TRIGGER reject_assignment');
    expect(await c.save(draft()), isTrue);
    final id = c.records.single.id!;
    await sql.execute(
      "CREATE TRIGGER reject_unassign BEFORE DELETE ON goal_records BEGIN SELECT RAISE(ABORT, '注入事务中失败'); END",
    );
    expect(await c.delete(id), isFalse);
    expect(c.writeCommitted, isFalse);
    expect((await db.readAll()).single.id, id);
    expect((await db.readSnapshot()).goal!.recordIds, {id});
    await sql.execute('DROP TRIGGER reject_unassign');
    expect(await c.delete(id), isTrue);
    expect(c.summary.goodChoices, 0);
    expect(c.goal!.recordIds, isEmpty);
  });
}
