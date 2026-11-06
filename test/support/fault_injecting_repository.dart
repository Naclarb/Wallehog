import 'dart:async';
import 'package:wallehog/domain/backup.dart';
import 'package:wallehog/domain/record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/domain/wishlist_goal.dart';

/// 在委托事务调用前、委托成功返回后和快照读取阶段分别控制故障。
/// 提交后只让下一阶段读取失败，不把成功事务伪装成写入失败。
class FaultInjectingRepository implements RecordRepository, BackupRepository {
  FaultInjectingRepository(this.delegate);
  final RecordRepository delegate;
  bool failBeforeWrite = false;
  bool failSnapshotAfterWrite = false;
  bool failSnapshot = false;
  Completer<void>? snapshotGate;
  final attempts = <String, int>{};
  final commits = <String, int>{};
  int snapshotReads = 0;

  Future<void> _write(String name, Future<void> Function() action) async {
    attempts.update(name, (n) => n + 1, ifAbsent: () => 1);
    if (failBeforeWrite) throw StateError('注入：事务调用前失败');
    await action();
    commits.update(name, (n) => n + 1, ifAbsent: () => 1);
    if (failSnapshotAfterWrite) failSnapshot = true;
  }

  @override
  Future<RecordSnapshot> readSnapshot() async {
    snapshotReads++;
    await snapshotGate?.future;
    if (failSnapshot) throw StateError('注入：事务已返回，快照读取失败');
    return delegate.readSnapshot();
  }

  @override
  Future<List<SavingRecord>> readAll() => delegate.readAll();
  @override
  Future<void> save(SavingRecord record) =>
      _write('save', () => delegate.save(record));
  @override
  Future<void> delete(int id) => _write('delete', () => delegate.delete(id));
  @override
  Future<void> createGoal(
    String name,
    int targetMinor, {
    String style = 'gift',
  }) => _write(
    'createGoal',
    () => delegate.createGoal(name, targetMinor, style: style),
  );
  @override
  Future<void> editGoal(String name, int targetMinor, {String? style}) =>
      _write(
        'editGoal',
        () => delegate.editGoal(name, targetMinor, style: style),
      );
  @override
  Future<void> clearGoal() => _write('clearGoal', delegate.clearGoal);
  @override
  Future<void> selectGoal(int id) =>
      _write('selectGoal', () => delegate.selectGoal(id));
  @override
  Future<SavingsBackup> exportBackup() =>
      (delegate as BackupRepository).exportBackup();
  @override
  Future<void> restoreBackup(SavingsBackup backup) => _write(
    'restoreBackup',
    () => (delegate as BackupRepository).restoreBackup(backup),
  );
  @override
  Future<void> close() => delegate.close();
}
