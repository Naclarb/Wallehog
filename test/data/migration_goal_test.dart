import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';

void main() {
  sqfliteFfiInit();
  final now = DateTime.now();
  SavingRecord quick(int amount, {SavingRecord? previous, String? token}) =>
      SavingRecord(
        id: previous?.id,
        kind: DecisionKind.quick,
        description: '',
        amountMinor: amount,
        clientToken: previous?.clientToken ?? token,
        occurredOn: '2020-01-01',
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
        today: now,
      );
  test('v1迁移保留旧数据及删除后的高水位，Goal在重开后正确', () async {
    final dir = await Directory.systemTemp.createTemp('wallehog_migration_');
    final dbPath = path.join(dir.path, 'migration.db');
    final v1 = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(
            await File('test/fixtures/schema_v1.sql').readAsString(),
          );
        },
      ),
    );
    final original = <String, Object?>{
      'kind': 'budget',
      'description': '原有记录',
      'baseline_minor': 3000,
      'actual_minor': 1000,
      'saved_minor': 2000,
      'currency_code': 'CNY',
      'occurred_on': '2020-01-01',
      'created_at_utc': now.toUtc().toIso8601String(),
      'updated_at_utc': now.toUtc().toIso8601String(),
    };
    await v1.insert('saving_records', {'id': 1, ...original});
    await v1.insert('saving_records', {'id': 8, ...original});
    await v1.delete('saving_records', where: 'id = 8');
    await v1.close();
    var repository = await SqliteRecordRepository.open(
      databasePath: dbPath,
      factory: databaseFactoryFfi,
    );
    addTearDown(() async {
      await repository.close();
      if (!path.isWithin(
            Directory.systemTemp.absolute.path,
            dir.absolute.path,
          ) ||
          !path.basename(dir.path).startsWith('wallehog_migration_')) {
        throw StateError('非测试目录');
      }
      await dir.delete(recursive: true);
    });
    final old = (await repository.readAll()).single;
    expect(old.id, 1);
    expect(old.description, '原有记录');
    expect(old.baselineMinor, 3000);
    expect(old.savedMinor, 2000);
    expect(old.createdAt, now.toUtc());
    await repository.createGoal('耳机', 10000);
    var snapshot = await repository.readSnapshot();
    expect(snapshot.goal!.startAfterId, 8);
    expect(snapshot.goal!.progressMinor(snapshot.records), 0);
    await repository.save(quick(2700));
    snapshot = await repository.readSnapshot();
    expect(snapshot.records.first.id, 9);
    expect(snapshot.goal!.progressMinor(snapshot.records), 2700);
    await repository.save(quick(9999, previous: old));
    snapshot = await repository.readSnapshot();
    expect(snapshot.goal!.progressMinor(snapshot.records), 2700);
    await repository.editGoal('新耳机', 20000);
    snapshot = await repository.readSnapshot();
    expect(snapshot.goal!.startAfterId, 8);
    expect(snapshot.goal!.progressMinor(snapshot.records), 2700);
    final latest = snapshot.records.first;
    await repository.save(quick(300, previous: latest));
    snapshot = await repository.readSnapshot();
    expect(snapshot.goal!.progressMinor(snapshot.records), 300);
    await repository.close();
    repository = await SqliteRecordRepository.open(
      databasePath: dbPath,
      factory: databaseFactoryFfi,
    );
    snapshot = await repository.readSnapshot();
    expect(snapshot.goal!.name, '新耳机');
    expect(snapshot.goal!.progressMinor(snapshot.records), 300);
    await repository.delete(latest.id!);
    snapshot = await repository.readSnapshot();
    expect(snapshot.goal!.progressMinor(snapshot.records), 0);
    await repository.clearGoal();
    expect((await repository.readSnapshot()).goal, isNull);
    await repository.createGoal('下一愿望', 5000);
    snapshot = await repository.readSnapshot();
    expect(snapshot.goal!.startAfterId, 9);
    expect(snapshot.goal!.progressMinor(snapshot.records), 0);
    await repository.save(quick(200));
    snapshot = await repository.readSnapshot();
    expect(snapshot.records.first.id, 10);
    expect(snapshot.goal!.progressMinor(snapshot.records), 200);
  });
  test('重试同一请求不重复记录，目标操作失败不覆盖旧状态', () async {
    final repository = await SqliteRecordRepository.open(
      databasePath: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    addTearDown(repository.close);
    await repository.save(quick(2700, token: 'once'));
    await repository.save(quick(2700, token: 'once'));
    expect((await repository.readAll()).length, 1);
    await expectLater(
      repository.save(quick(200, token: 'once')),
      throwsException,
    );
    expect((await repository.readAll()).single.savedMinor, 2700);
    await repository.createGoal('目标', 10000);
    await repository.createGoal('第二心愿', 20000);
    expect((await repository.readSnapshot()).goals.length, 2);
    await repository.selectGoal(
      (await repository.readSnapshot()).goals.first.id!,
    );
    await expectLater(repository.editGoal('错误目标', 0), throwsException);
    expect((await repository.readSnapshot()).goal!.targetMinor, 10000);
    await repository.clearGoal();
    await repository.clearGoal();
    await expectLater(repository.editGoal('已清除', 20000), throwsException);
  });
}
