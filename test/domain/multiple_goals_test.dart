import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/domain/backup.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/domain/wishlist_goal.dart';

void main() {
  final now = DateTime.now();
  SavingRecord record(int id, int amount) => SavingRecord(
    id: id,
    kind: DecisionKind.quick,
    description: '',
    amountMinor: amount,
    occurredOn: dateKey(now),
    createdAt: now,
    updatedAt: now,
    today: now,
  );
  test('显式归属优先于顺序边界，删除编辑只重算原心愿', () {
    final records = [record(1, 2700), record(2, 300)];
    final a = WishlistGoal(
      id: 1,
      name: 'PS5',
      targetMinor: 1000,
      startAfterId: 0,
      style: 'ps5',
      recordIds: {1},
    );
    final b = WishlistGoal(
      id: 2,
      name: '耳机',
      targetMinor: 1000,
      startAfterId: 0,
      style: 'headphones',
      recordIds: {2},
    );
    expect(a.progressMinor(records), 2700);
    expect(a.progressFraction(records), 1);
    expect(b.progressMinor(records), 300);
    expect(a.progressMinor([record(1, 5000), record(2, 300)]), 5000);
    expect(b.progressMinor([record(1, 5000)]), 0);
    expect(SavingsSummary.fromRecords(records).savedMinor, 3000);
  });
  test('备份拒绝跨心愿重复归属、缺失记录与错误选中，v1 可恢复', () {
    final source = SavingsBackup.create(
      records: [record(1, 2700)],
      goal: WishlistGoal(
        id: 1,
        name: 'PS5',
        targetMinor: 400000,
        startAfterId: 0,
        style: 'ps5',
        recordIds: {1},
      ),
      highWater: 1,
      exportedAt: now,
    ).encode();
    Map<String, dynamic> root() => jsonDecode(source) as Map<String, dynamic>;
    final duplicate = root();
    (duplicate['goals'] as List).add({
      ...((duplicate['goals'] as List).first as Map),
      'id': 2,
    });
    expect(() => SavingsBackup.decode(jsonEncode(duplicate)), throwsException);
    final missing = root();
    missing['goals'][0]['recordIds'] = [2];
    expect(() => SavingsBackup.decode(jsonEncode(missing)), throwsException);
    final selected = root();
    selected['selectedGoalId'] = 99;
    expect(() => SavingsBackup.decode(jsonEncode(selected)), throwsException);
    final legacy = root()..['version'] = 1;
    legacy['goal'] = {'name': '旧目标', 'targetMinor': 10000, 'startAfterId': 0};
    legacy.remove('goals');
    legacy.remove('selectedGoalId');
    final restored = SavingsBackup.decode(jsonEncode(legacy));
    expect(restored.goals.length, 1);
    expect(restored.goal!.progressMinor(restored.records), 2700);
  });
}
