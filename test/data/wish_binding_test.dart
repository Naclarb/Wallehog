import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/backup.dart';
import 'package:wallehog/domain/saving_record.dart';

void main() {
  sqfliteFfiInit();
  late SqliteRecordRepository repo;
  SavingRecord record(int amount, {SavingRecord? old, String? token}) {
    final now = DateTime.now();
    return SavingRecord(
      id: old?.id,
      kind: DecisionKind.quick,
      description: '',
      amountMinor: amount,
      clientToken: old?.clientToken ?? token,
      occurredOn: old?.occurredOn ?? dateKey(now),
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      today: now,
    );
  }

  setUp(() async {
    repo = await SqliteRecordRepository.open(
      databasePath: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() => repo.close());

  test(
    'first wish adopts unbound savings; additional wishes and switching do not',
    () async {
      await repo.save(record(1200));
      await repo.save(record(300));
      await repo.createGoal('A', 10000);
      var snapshot = await repo.readSnapshot();
      final first = snapshot.goal!.id!;
      expect(snapshot.goal!.progressMinor(snapshot.records), 1500);
      await repo.save(record(200), updateGoal: true);
      await repo.createGoal('B', 20000);
      snapshot = await repo.readSnapshot();
      expect(snapshot.goal!.progressMinor(snapshot.records), 0);
      await repo.selectGoal(first);
      snapshot = await repo.readSnapshot();
      expect(snapshot.goal!.progressMinor(snapshot.records), 1500);
      expect(SavingsSummary.fromRecords(snapshot.records).savedMinor, 1700);
    },
  );

  test('rebind older record atomically and round trip v2 backup', () async {
    await repo.save(record(1200));
    await repo.createGoal('A', 10000);
    await repo.createGoal('B', 10000);
    var snapshot = await repo.readSnapshot();
    final b = snapshot.goal!.id!;
    final old = snapshot.records.single;
    await repo.save(record(1300, old: old), goalId: b, updateGoal: true);
    snapshot = await repo.readSnapshot();
    expect(snapshot.goals.first.progressMinor(snapshot.records), 0);
    expect(snapshot.goal!.progressMinor(snapshot.records), 1300);
    expect(snapshot.records.single.id, old.id);
    expect(snapshot.records.single.createdAt, old.createdAt);
    final backup = SavingsBackup.decode((await repo.exportBackup()).encode());
    await repo.clearGoal();
    await repo.restoreBackup(backup);
    snapshot = await repo.readSnapshot();
    expect(snapshot.goal!.progressMinor(snapshot.records), 1300);
    await repo.save(
      record(1300, old: snapshot.records.single),
      updateGoal: true,
    );
    snapshot = await repo.readSnapshot();
    expect(snapshot.goals.every((g) => g.recordIds!.isEmpty), isTrue);
    expect(SavingsSummary.fromRecords(snapshot.records).savedMinor, 1300);
  });

  test('deleting last wish and creating one adopts retained records', () async {
    await repo.createGoal('A', 10000);
    await repo.save(record(1200));
    await repo.clearGoal();
    await repo.createGoal('B', 10000);
    final snapshot = await repo.readSnapshot();
    expect(snapshot.goal!.progressMinor(snapshot.records), 1200);
    expect(snapshot.records.length, 1);
  });

  test(
    'invalid destination does not change amount or original assignment',
    () async {
      await repo.createGoal('A', 10000);
      await repo.save(record(1200));
      final old = (await repo.readSnapshot()).records.single;
      await expectLater(
        repo.save(record(5000, old: old), goalId: 999, updateGoal: true),
        throwsA(anything),
      );
      final snapshot = await repo.readSnapshot();
      expect(snapshot.goal!.progressMinor(snapshot.records), 1200);
    },
  );

  test(
    'assignment failure rolls back new wish, selection, and all adopted records',
    () async {
      await repo.save(record(100));
      await repo.save(record(200));
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await db.execute(
        "CREATE TRIGGER reject_adoption BEFORE INSERT ON goal_records WHEN NEW.record_id=2 BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      try {
        await expectLater(repo.createGoal('A', 10000), throwsA(anything));
        final snapshot = await repo.readSnapshot();
        expect(snapshot.goals, isEmpty);
        expect(snapshot.goal, isNull);
        expect(snapshot.records.length, 2);
      } finally {
        await db.execute('DROP TRIGGER reject_adoption');
      }
      await repo.createGoal('A', 10000);
      final snapshot = await repo.readSnapshot();
      expect(snapshot.goal!.progressMinor(snapshot.records), 300);
    },
  );

  test('retry with same token cannot duplicate or silently rebind', () async {
    await repo.createGoal('A', 10000);
    final a = (await repo.readSnapshot()).goal!.id!;
    final input = record(200, token: 'binding-retry');
    await repo.save(input, goalId: a, updateGoal: true);
    await repo.save(input, goalId: a, updateGoal: true);
    await expectLater(repo.save(input, updateGoal: true), throwsA(anything));
    final snapshot = await repo.readSnapshot();
    expect(snapshot.records.length, 1);
    expect(snapshot.goal!.progressMinor(snapshot.records), 200);
  });
}
