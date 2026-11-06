import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/domain/expression_parser.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/domain/wishlist_goal.dart';

void main() {
  final now = DateTime.now();
  SavingRecord quick(int amount, {int? id, String date = '2020-01-01'}) =>
      SavingRecord(
        id: id,
        kind: DecisionKind.quick,
        description: '',
        amountMinor: amount,
        occurredOn: date,
        createdAt: now,
        updatedAt: now,
        today: now,
      );
  test('27直接保存，无分类/预算/备注', () {
    final r = quick(evaluateMoney('27'));
    expect(r.savedMinor, 2700);
    expect(r.description, isEmpty);
    expect(SavingsSummary.fromRecords([r]).goodChoices, 1);
  });
  for (final amount in [0, -1, maxMoneyMinor + 1]) {
    test('快速记录拒绝 $amount', () {
      expect(() => quick(amount), throwsA(isA<RuleViolation>()));
    });
  }
  test('快速记录不接受预算字段', () {
    expect(
      () => SavingRecord(
        kind: DecisionKind.quick,
        description: '',
        amountMinor: 200,
        baselineMinor: 300,
        occurredOn: dateKey(now),
        createdAt: now,
        updatedAt: now,
        today: now,
      ),
      throwsA(isA<RuleViolation>()),
    );
  });
  test('目标仅按不可变ID边界，忽略发生日期', () {
    final goal = WishlistGoal(
      name: ' 耳机 ',
      targetMinor: 10000,
      startAfterId: 5,
    );
    expect(goal.name, '耳机');
    expect(goal.progressMinor([quick(9000, id: 5), quick(200, id: 6)]), 200);
    expect(goal.progressFraction([quick(20000, id: 6)]), 1);
    expect(goal.progressMinor([quick(20000, id: 6)]), 20000);
    expect(goal.progressMinor([quick(200, id: 5)]), 0);
    expect(goal.progressMinor([quick(200)]), 0);
  });
  for (final name in ['', ' ', '字' * 61]) {
    test('目标名称边界 ${name.length}', () {
      expect(
        () => WishlistGoal(name: name, targetMinor: 100, startAfterId: 0),
        throwsA(isA<RuleViolation>()),
      );
    });
  }
  for (final target in [0, -1, maxMoneyMinor + 1]) {
    test('目标金额边界 $target', () {
      expect(
        () => WishlistGoal(name: '目标', targetMinor: target, startAfterId: 0),
        throwsA(isA<RuleViolation>()),
      );
    });
  }
  test('目标边界不能为负', () {
    expect(
      () => WishlistGoal(name: '目标', targetMinor: 100, startAfterId: -1),
      throwsA(isA<RuleViolation>()),
    );
  });
}
