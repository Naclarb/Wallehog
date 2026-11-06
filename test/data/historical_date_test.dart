import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/backup.dart';
import 'package:wallehog/domain/saving_record.dart';

void main() {
  sqfliteFfiInit();
  test('历史记录在日期回退、跨时区日界和重启后可读，日期原样保留', () async {
    final dir = await Directory.systemTemp.createTemp('wallehog_date_test_');
    final dbPath = path.join(dir.path, 'records.db');
    var clock = DateTime(2026, 10, 25, 0, 30);
    var repo = await SqliteRecordRepository.open(
      databasePath: dbPath,
      factory: databaseFactoryFfi,
      clock: () => clock,
    );
    addTearDown(() async {
      await repo.close();
      if (!path.isWithin(
            Directory.systemTemp.absolute.path,
            dir.absolute.path,
          ) ||
          !path.basename(dir.path).startsWith('wallehog_date_test_')) {
        throw StateError('临时目录不合法');
      }
      await dir.delete(recursive: true);
    });
    await repo.createGoal('历史心愿', 10000);
    await repo.save(
      SavingRecord(
        kind: DecisionKind.quick,
        description: '',
        amountMinor: 1234,
        clientToken: 'date-test',
        occurredOn: '2026-10-25',
        createdAt: clock,
        updatedAt: clock,
        today: clock,
      ),
    );
    final backup = await repo.exportBackup();
    final instant = DateTime.utc(2026, 10, 25, 1);
    // 同一时刻 UTC+8 是 25 日、UTC-7 是 24 日；注入本地日历而不改测试机时区。
    expect(dateKey(instant.add(const Duration(hours: 8))), '2026-10-25');
    for (final shifted in [
      instant.subtract(const Duration(hours: 7)),
      DateTime(2025, 1, 1),
    ]) {
      await repo.restoreBackup(backup);
      clock = DateTime(shifted.year, shifted.month, shifted.day);
      var snapshot = await repo.readSnapshot();
      expect(snapshot.records.single.occurredOn, '2026-10-25');
      expect(snapshot.goal!.progressMinor(snapshot.records), 1234);
      expect(
        SavingsBackup.decode(
          backup.encode(),
          today: clock,
        ).records.single.occurredOn,
        '2026-10-25',
      );
      await repo.close();
      repo = await SqliteRecordRepository.open(
        databasePath: dbPath,
        factory: databaseFactoryFfi,
        clock: () => clock,
      );
      snapshot = await repo.readSnapshot();
      expect(snapshot.records.single.occurredOn, '2026-10-25');
      await repo.restoreBackup(backup);
      expect((await repo.readAll()).single.savedMinor, 1234);
      // 仍允许今天的新记录，不会因历史记录被当成未来日期而回滚。
      await repo.save(
        SavingRecord(
          kind: DecisionKind.quick,
          description: '',
          amountMinor: 100,
          occurredOn: dateKey(clock),
          createdAt: clock,
          updatedAt: clock,
          today: clock,
        ),
      );
      expect((await repo.readAll()).length, 2);
      final original = (await repo.readAll()).singleWhere(
        (r) => r.clientToken == 'date-test',
      );
      // 保留历史日期的编辑仍有效，归属不变；新建/修改为另一个未来日期仍拒绝。
      final edited = SavingRecord.fromStorage(
        id: original.id,
        kind: original.kind,
        description: '日期未改的编辑',
        amountMinor: 1300,
        clientToken: original.clientToken,
        occurredOn: original.occurredOn,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
      );
      await repo.save(edited);
      final editedSnapshot = await repo.readSnapshot();
      expect(editedSnapshot.goal!.recordIds, contains(original.id));
      expect(
        editedSnapshot.records
            .singleWhere((r) => r.id == original.id)
            .occurredOn,
        '2026-10-25',
      );
      // 幂等重放已存在的请求不受日期回退影响，也不会再增加记录。
      await repo.save(
        SavingRecord.fromStorage(
          kind: edited.kind,
          description: edited.description,
          amountMinor: edited.savedMinor,
          clientToken: edited.clientToken,
          occurredOn: edited.occurredOn,
          createdAt: edited.createdAt,
          updatedAt: edited.updatedAt,
        ),
      );
      expect((await repo.readAll()).length, 2);
      final invalidDate = dateKey(clock.add(const Duration(days: 2)));
      for (final id in [null, original.id]) {
        final invalid = SavingRecord.fromStorage(
          id: id,
          kind: original.kind,
          description: '',
          amountMinor: 100,
          clientToken: id == null ? null : original.clientToken,
          occurredOn: invalidDate,
          createdAt: original.createdAt,
          updatedAt: original.updatedAt,
        );
        await expectLater(repo.save(invalid), throwsException);
      }
    }
    // 损坏的日期仍拒绝，不因历史读取模式而放宽日历合法性。
    for (final invalid in ['2026-02-30', '2026-1-01', 'invalid']) {
      final root = jsonDecode(backup.encode()) as Map<String, dynamic>;
      (root['records'] as List).first['occurredOn'] = invalid;
      expect(
        () => SavingsBackup.decode(jsonEncode(root), today: clock),
        throwsException,
      );
      final sql = await databaseFactoryFfi.openDatabase(dbPath);
      await sql.update(
        'saving_records',
        {'occurred_on': invalid},
        where: 'client_token=?',
        whereArgs: ['date-test'],
      );
      await expectLater(repo.readSnapshot(), throwsException);
      await sql.update(
        'saving_records',
        {'occurred_on': '2026-10-25'},
        where: 'client_token=?',
        whereArgs: ['date-test'],
      );
      expect(
        (await repo.readAll())
            .singleWhere((r) => r.clientToken == 'date-test')
            .occurredOn,
        '2026-10-25',
      );
    }
  });
}
