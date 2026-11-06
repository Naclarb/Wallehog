import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';

void main() {
  sqfliteFfiInit();
  late SqliteRecordRepository repo;
  final now = DateTime.now();
  SavingRecord record(int amount) => SavingRecord(
    kind: DecisionKind.quick,
    description: '',
    amountMinor: amount,
    occurredOn: '2020-01-01',
    createdAt: now,
    updatedAt: now,
    today: now,
  );
  setUp(() async {
    repo = await SqliteRecordRepository.open(
      databasePath: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() => repo.close());
  test('整体恢复替换当前数据、保留边界和删除后的序列', () async {
    await repo.save(record(100));
    await repo.save(record(200));
    await repo.delete(2);
    await repo.createGoal('旅行', 1000);
    await repo.save(record(300));
    final backup = await repo.exportBackup();
    await repo.clearGoal();
    await repo.save(record(999));
    await repo.restoreBackup(backup);
    var snapshot = await repo.readSnapshot();
    expect(snapshot.records.map((r) => r.savedMinor), [300, 100]);
    expect(snapshot.goal!.startAfterId, 2);
    expect(snapshot.goal!.progressMinor(snapshot.records), 300);
    await repo.save(record(400));
    snapshot = await repo.readSnapshot();
    expect(snapshot.records.first.id, 4);
    await repo.clearGoal();
    await repo.createGoal('新心愿', 1000);
    expect((await repo.readSnapshot()).goal!.startAfterId, 4);
  });
  test('恢复没有现存记录的备份仍保留历史高水位', () async {
    await repo.save(record(100));
    await repo.delete(1);
    final backup = await repo.exportBackup();
    await repo.restoreBackup(backup);
    await repo.createGoal('新心愿', 1000);
    expect((await repo.readSnapshot()).goal!.startAfterId, 1);
    await repo.save(record(200));
    expect((await repo.readAll()).single.id, 2);
  });
  test('事务中途插入失败，原有记录和心愿全部回滚', () async {
    await repo.save(record(100));
    final backup = await repo.exportBackup();
    await repo.save(record(200));
    await repo.createGoal('保留的心愿', 1000);
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      "CREATE TRIGGER reject_restore BEFORE INSERT ON saving_records BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(repo.restoreBackup(backup), throwsA(anything));
    final snapshot = await repo.readSnapshot();
    expect(snapshot.records.length, 2);
    expect(snapshot.goal!.name, '保留的心愿');
    await db.execute('DROP TRIGGER reject_restore');
  });
}
