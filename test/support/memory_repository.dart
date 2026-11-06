import 'dart:math';
import 'package:wallehog/domain/pig_growth.dart';
import 'package:wallehog/domain/record_repository.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/domain/wishlist_goal.dart';

class MemoryRepository implements RecordRepository, GrowthCelebrationStore {
  final celebratedLevels = <int>{};
  @override
  Future<bool> claimGrowthCelebration(int level) async =>
      celebratedLevels.add(level);
  final records = <SavingRecord>[];
  bool fail = false;
  bool failRead = false;
  int highWater = 0;
  WishlistGoal? goal;
  final goals = <WishlistGoal>[];
  final assignments = <int, int>{};
  int goalHighWater = 0;
  WishlistGoal _withAssignments(WishlistGoal g) => WishlistGoal(
    id: g.id,
    name: g.name,
    targetMinor: g.targetMinor,
    startAfterId: g.startAfterId,
    style: g.style,
    recordIds: assignments.entries
        .where((e) => e.value == g.id)
        .map((e) => e.key)
        .toSet(),
  );
  @override
  Future<List<SavingRecord>> readAll() async {
    if (fail || failRead) throw StateError('测试读失败');
    return List.of(records)..sort((a, b) => b.id!.compareTo(a.id!));
  }

  @override
  Future<RecordSnapshot> readSnapshot() async {
    final rows = await readAll();
    final all = goals.map(_withAssignments).toList();
    return RecordSnapshot(
      rows,
      all.where((g) => g.id == goal?.id).firstOrNull,
      allGoals: all,
    );
  }

  @override
  Future<void> save(SavingRecord record) async {
    if (fail) throw StateError('测试写失败');
    if (record.id == null &&
        record.clientToken != null &&
        records.any((r) => r.clientToken == record.clientToken)) {
      return;
    }
    final id = record.id ?? ++highWater;
    if (record.id == null && goal != null) assignments[id] = goal!.id!;
    highWater = max(highWater, id);
    records.removeWhere((r) => r.id == id);
    records.add(
      SavingRecord(
        id: id,
        kind: record.kind,
        description: record.description,
        baselineMinor: record.baselineMinor,
        actualMinor: record.actualMinor,
        amountMinor: record.amountMinor,
        clientToken: record.clientToken,
        occurredOn: record.occurredOn,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
        today: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> delete(int id) async {
    if (fail) throw StateError('测试删除失败');
    records.removeWhere((r) => r.id == id);
    assignments.remove(id);
  }

  @override
  Future<void> createGoal(
    String name,
    int targetMinor, {
    String style = 'gift',
  }) async {
    if (fail) throw StateError('测试写失败');
    if (goals.length >= 50) throw StateError('心愿上限');
    goal = WishlistGoal(
      id: ++goalHighWater,
      style: style,
      name: name,
      targetMinor: targetMinor,
      startAfterId: highWater,
    );
    goals.add(goal!);
  }

  @override
  Future<void> editGoal(String name, int targetMinor, {String? style}) async {
    if (fail || goal == null) throw StateError('目标不可修改');
    goal = WishlistGoal(
      id: goal!.id,
      style: style ?? goal!.style,
      name: name,
      targetMinor: targetMinor,
      startAfterId: goal!.startAfterId,
    );
    goals[goals.indexWhere((g) => g.id == goal!.id)] = goal!;
  }

  @override
  Future<void> clearGoal() async {
    if (fail) throw StateError('测试写失败');
    goals.removeWhere((g) => g.id == goal?.id);
    assignments.removeWhere((id, goalId) => goalId == goal?.id);
    goal = goals.firstOrNull;
  }

  @override
  Future<void> selectGoal(int id) async {
    if (fail) throw StateError('测试写失败');
    goal = goals.firstWhere((g) => g.id == id);
  }

  @override
  Future<void> close() async {}
}
