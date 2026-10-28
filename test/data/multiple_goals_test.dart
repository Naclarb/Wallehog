import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/domain/backup.dart';

void main() {
  sqfliteFfiInit();
  test('v3 单心愿迁移不改变旧进度与已庆祝等级', () async {
    final dir = await Directory.systemTemp.createTemp('wallehog_v3_');
    final location = '${dir.path}/test.db';
    var repo = await SqliteRecordRepository.open(
      databasePath: location,
      factory: databaseFactoryFfi,
    );
    final now = DateTime.now();
    Future<void> save(int amount) => repo.save(
      SavingRecord(
        kind: DecisionKind.quick,
        description: '',
        amountMinor: amount,
        occurredOn: dateKey(now),
        createdAt: now,
        updatedAt: now,
        today: now,
      ),
    );
    await save(1000);
    await repo.createGoal('保留的心愿', 10000);
    await save(2700);
    await repo.claimGrowthCelebration(2);
    await repo.close();
    final old = await databaseFactoryFfi.openDatabase(location);
    await old.execute(
      'CREATE TABLE active_goal (id INTEGER PRIMARY KEY CHECK(id=1), name TEXT NOT NULL, target_minor INTEGER NOT NULL, start_after_id INTEGER NOT NULL)',
    );
    await old.execute(
      'INSERT INTO active_goal SELECT id,name,target_minor,start_after_id FROM goals',
    );
    await old.execute('DROP TABLE goal_selection');
    await old.execute('DROP TABLE goal_records');
    await old.execute('DROP TABLE goals');
    await old.setVersion(3);
    await old.close();
    repo = await SqliteRecordRepository.open(
      databasePath: location,
      factory: databaseFactoryFfi,
    );
    try {
      final snapshot = await repo.readSnapshot();
      expect(snapshot.goal!.progressMinor(snapshot.records), 2700);
      expect(snapshot.goal!.startAfterId, 1);
      expect(SavingsSummary.fromRecords(snapshot.records).savedMinor, 3700);
      expect(await repo.claimGrowthCelebration(2), isFalse);
      await repo.createGoal('PS5', 400000, style: 'ps5');
      expect(
        (await repo.readSnapshot()).goal!.progressMinor(snapshot.records),
        0,
      );
    } finally {
      await repo.close();
      await dir.delete(recursive: true);
    }
  });
  test('心愿切换、编辑删除、备份与重启保留唯一归属', () async {
    final dir = await Directory.systemTemp.createTemp('wallehog_multi_');
    final location = '${dir.path}/test.db';
    var repo = await SqliteRecordRepository.open(
      databasePath: location,
      factory: databaseFactoryFfi,
    );
    addTearDown(() async {
      await repo.close();
      await dir.delete(recursive: true);
    });
    SavingRecord record(int amount, {SavingRecord? old}) {
      final now = DateTime.now();
      return SavingRecord(
        id: old?.id,
        kind: DecisionKind.quick,
        description: '',
        amountMinor: amount,
        occurredOn: dateKey(now),
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
        today: now,
      );
    }

    await repo.createGoal('PS5', 400000, style: 'ps5');
    final first = (await repo.readSnapshot()).goal!;
    await repo.save(record(2700));
    await repo.createGoal('耳机', 100000, style: 'headphones');
    final second = (await repo.readSnapshot()).goal!;
    await repo.save(record(300));
    var snapshot = await repo.readSnapshot();
    expect(snapshot.goals.length, 2);
    expect(snapshot.goals.first.progressMinor(snapshot.records), 2700);
    expect(snapshot.goal!.progressMinor(snapshot.records), 300);
    await repo.selectGoal(first.id!);
    final secondRecord = snapshot.records.first;
    await repo.save(record(500, old: secondRecord));
    snapshot = await repo.readSnapshot();
    expect(snapshot.goal!.progressMinor(snapshot.records), 2700);
    expect(snapshot.goals.last.progressMinor(snapshot.records), 500);
    final backup = SavingsBackup.decode((await repo.exportBackup()).encode());
    expect(backup.goals.length, 2);
    await repo.clearGoal();
    expect((await repo.readAll()).length, 2);
    await repo.restoreBackup(backup);
    await repo.close();
    repo = await SqliteRecordRepository.open(
      databasePath: location,
      factory: databaseFactoryFfi,
    );
    snapshot = await repo.readSnapshot();
    expect(snapshot.goal!.id, first.id);
    expect(snapshot.goals.last.id, second.id);
    expect(SavingsSummary.fromRecords(snapshot.records).savedMinor, 3200);
    await repo.delete(secondRecord.id!);
    snapshot = await repo.readSnapshot();
    expect(snapshot.goals.last.progressMinor(snapshot.records), 0);
    expect(snapshot.goal!.progressMinor(snapshot.records), 2700);
  });
}
