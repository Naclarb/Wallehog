import 'package:flutter/foundation.dart';
import '../domain/record_repository.dart';
import '../domain/saving_record.dart';
import '../domain/wishlist_goal.dart';
import '../domain/expression_parser.dart';
import '../domain/backup.dart';

class RecordsController extends ChangeNotifier {
  RecordsController(this.repository);
  final RecordRepository repository;
  List<SavingRecord> records = const [];
  SavingsSummary summary = const SavingsSummary(0, 0);
  bool busy = false;
  bool loaded = false;
  bool needsRecovery = false;
  bool get canWrite => loaded && !busy && !needsRecovery;
  static const _recoveryMessage = '数据已保存，但暂时无法读取最新结果。请重新读取后继续，不会重复提交。';
  String? error;
  WishlistGoal? goal;
  List<WishlistGoal> goals = const [];
  bool writeCommitted = false;
  int get goalProgressMinor => goal?.progressMinor(records) ?? 0;
  bool get supportsBackup => repository is BackupRepository;
  Future<SavingsBackup> exportBackup() async {
    SavingsBackup? result;
    final success = await _perform(() async {
      result = await (repository as BackupRepository).exportBackup();
    }, requiresSnapshot: true);
    if (!success) throw RuleViolation(error ?? '导出失败，请重试');
    return result!;
  }

  Future<bool> restoreBackup(SavingsBackup backup) =>
      _write(() => (repository as BackupRepository).restoreBackup(backup));

  Future<void> _refresh() async {
    final next = await repository.readSnapshot();
    final totals = SavingsSummary.fromRecords(next.records);
    records = List.unmodifiable(next.records);
    goal = next.goal;
    goals = List.unmodifiable(next.goals);
    summary = totals;
    loaded = true;
    needsRecovery = false;
  }

  Future<bool> load() => _perform(_refresh);
  Future<bool> save(SavingRecord record) =>
      _write(() => repository.save(record));
  Future<bool> delete(int id) => _write(() => repository.delete(id));
  Future<bool> createGoal(
    String name,
    int targetMinor, {
    String style = 'gift',
  }) => _write(() => repository.createGoal(name, targetMinor, style: style));
  Future<bool> editGoal(String name, int targetMinor, {String? style}) =>
      _write(() => repository.editGoal(name, targetMinor, style: style));
  Future<bool> clearGoal() => _write(repository.clearGoal);

  Future<bool> selectGoal(int id) => _write(() => repository.selectGoal(id));

  Future<bool> _write(Future<void> Function() operation) => _perform(() async {
    await operation();
    writeCommitted = true;
    await _refresh();
  }, requiresSnapshot: true);

  Future<bool> _perform(
    Future<void> Function() operation, {
    bool requiresSnapshot = false,
  }) async {
    if (busy) return false;
    if (requiresSnapshot && !canWrite) {
      // 拒绝的是本次写入；全局恢复状态独立保留，只有成功读取可解除。
      writeCommitted = false;
      error = needsRecovery ? _recoveryMessage : '请先读取本地数据后继续。';
      notifyListeners();
      return false;
    }
    busy = true;
    writeCommitted = false;
    error = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } catch (e) {
      if (writeCommitted) {
        needsRecovery = true;
        loaded = false;
      }
      error = needsRecovery
          ? _recoveryMessage
          : e is RuleViolation
          ? e.message
          : '本地操作暂未完成，请重试。输入已保留。';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
