import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wallehog/data/sqlite_record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';

void main() {
  sqfliteFfiInit();
  test('真实SQLite文件：新增、编辑、类型转换、删除、关闭重开及约束', () async {
    final dir = await Directory.systemTemp.createTemp('wallehog_test_');
    final dbPath = path.join(dir.path, 'records.db');
    final now = DateTime.now();
    var repository = await SqliteRecordRepository.open(
      databasePath: dbPath,
      factory: databaseFactoryFfi,
    );
    addTearDown(() async {
      await repository.close();
      final resolved = dir.absolute.path;
      final tempRoot = Directory.systemTemp.absolute.path;
      if (!path.isWithin(tempRoot, resolved) ||
          !path.basename(resolved).startsWith('wallehog_test_')) {
        throw StateError('拒绝清理非测试临时目录');
      }
      await dir.delete(recursive: true);
    });
    SavingRecord record({
      int? id,
      DecisionKind kind = DecisionKind.budget,
      int? baseline = 3000,
      int? actual = 1500,
    }) => SavingRecord(
      id: id,
      kind: kind,
      description: '测试好选择',
      baselineMinor: baseline,
      actualMinor: actual,
      occurredOn: dateKey(now),
      createdAt: now,
      updatedAt: now,
      today: now,
    );
    await repository.save(record());
    await repository.save(
      record(kind: DecisionKind.forgone, baseline: null, actual: null),
    );
    var records = await repository.readAll();
    final id = records.firstWhere((r) => r.kind == DecisionKind.budget).id!;
    expect(SavingsSummary.fromRecords(records).savedMinor, 1500);
    await repository.save(record(id: id, actual: 2000));
    expect(
      SavingsSummary.fromRecords(await repository.readAll()).savedMinor,
      1000,
    );
    await repository.close();
    repository = await SqliteRecordRepository.open(
      databasePath: dbPath,
      factory: databaseFactoryFfi,
    );
    expect(
      SavingsSummary.fromRecords(await repository.readAll()).goodChoices,
      2,
    );
    await repository.save(
      record(id: id, kind: DecisionKind.forgone, baseline: null, actual: null),
    );
    expect(
      SavingsSummary.fromRecords(await repository.readAll()).savedMinor,
      0,
    );
    await repository.delete(id);
    expect((await repository.readAll()).length, 1);
    await expectLater(repository.save(record(id: 99999)), throwsException);
    await expectLater(repository.delete(99999), throwsException);
    expect((await repository.readAll()).length, 1);
    final wrongCreated = SavingRecord(
      id: (await repository.readAll()).single.id,
      kind: DecisionKind.forgone,
      description: '不能篡改创建时间',
      occurredOn: dateKey(now),
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
      today: now,
    );
    await expectLater(repository.save(wrongCreated), throwsException);
    expect((await repository.readAll()).single.description, '测试好选择');
  });
  test('事务内验证失败会回滚，不留半条记录', () async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final repository = await SqliteRecordRepository.open(
      databasePath: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
      clock: () => now,
    );
    addTearDown(repository.close);
    final invalidForDatabase = SavingRecord(
      kind: DecisionKind.forgone,
      description: '模拟过期表单/设备日期变动',
      occurredOn: dateKey(tomorrow),
      createdAt: now,
      updatedAt: now,
      today: tomorrow,
    );
    await expectLater(repository.save(invalidForDatabase), throwsException);
    expect(await repository.readAll(), isEmpty);
  });
}
