import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/pig_growth.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/application/records_controller.dart';

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
  sqfliteFfiInit();
  test('SQLite 编辑删除、重开后真实等级与永久庆祝去重独立', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.close();
    final dir = await Directory.systemTemp.createTemp('wallehog_growth_');
    final file = '${dir.path}/growth.db';
    var repo = await SqliteRecordRepository.open(
      databasePath: file,
      factory: databaseFactoryFfi,
    );
    var c = RecordsController(repo);
    try {
      await c.load();
      for (var i = 0; i < 60; i++) {
        await c.save(quick(i == 0 ? 999999999 : 1));
        expect(PigGrowth(c.summary.goodChoices).level, PigGrowth(i + 1).level);
      }
      for (var level = 2; level <= 5; level++) {
        final results = await Future.wait([
          repo.claimGrowthCelebration(level),
          repo.claimGrowthCelebration(level),
        ]);
        expect(results.where((r) => r).length, 1);
      }
      final record = c.records.first;
      await c.save(quick(2700, previous: record));
      expect(PigGrowth(c.summary.goodChoices).level, 5);
      await c.delete(record.id!);
      expect(PigGrowth(c.summary.goodChoices).level, 4);
      c.dispose();
      await repo.close();
      repo = await SqliteRecordRepository.open(
        databasePath: file,
        factory: databaseFactoryFfi,
      );
      c = RecordsController(repo);
      await c.load();
      expect(c.summary.goodChoices, 59);
      expect(PigGrowth(c.summary.goodChoices).level, 4);
      await c.save(quick(1));
      expect(PigGrowth(c.summary.goodChoices).level, 5);
      for (var level = 2; level <= 5; level++) {
        expect(await repo.claimGrowthCelebration(level), isFalse);
      }
      expect(() => repo.claimGrowthCelebration(1), throwsArgumentError);
    } finally {
      c.dispose();
      await repo.close();
      await File(file).delete();
      await dir.delete();
    }
  });
  test('v2 到 v4 保留记录、目标和历史序列并新增庆祝及多心愿', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.close();
    final dir = await Directory.systemTemp.createTemp(
      'wallehog_growth_migration_',
    );
    final file = '${dir.path}/growth.db';
    var repo = await SqliteRecordRepository.open(
      databasePath: file,
      factory: databaseFactoryFfi,
    );
    try {
      await repo.save(quick(2700));
      await repo.createGoal('耳机', 10000);
      await repo.close();
      final v2 = await databaseFactoryFfi.openDatabase(file);
      await v2.execute(
        'CREATE TABLE active_goal (id INTEGER PRIMARY KEY, name TEXT, target_minor INTEGER, start_after_id INTEGER)',
      );
      await v2.execute(
        'INSERT INTO active_goal SELECT id,name,target_minor,start_after_id FROM goals',
      );
      await v2.execute('DROP TABLE goal_records');
      await v2.execute('DROP TABLE goal_selection');
      await v2.execute('DROP TABLE goals');
      await v2.execute('DROP TABLE pig_celebrations');
      await v2.setVersion(2);
      await v2.close();
      repo = await SqliteRecordRepository.open(
        databasePath: file,
        factory: databaseFactoryFfi,
      );
      final snapshot = await repo.readSnapshot();
      expect(snapshot.records.single.savedMinor, 2700);
      expect(snapshot.goal!.startAfterId, 1);
      expect(await repo.claimGrowthCelebration(2), isTrue);
      await repo.save(quick(1));
      expect((await repo.readAll()).first.id, 2);
    } finally {
      await repo.close();
      await File(file).delete();
      await dir.delete();
    }
  });
}
