import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/domain/expression_parser.dart';
import 'package:wallehog/domain/saving_record.dart';

void main() {
  final now = DateTime.utc(2026, 10, 22, 12);
  SavingRecord record({
    DecisionKind kind = DecisionKind.budget,
    int? baseline = 3000,
    int? actual = 1500,
    String description = '少买一杯饮料',
    String date = '2026-10-22',
    DateTime? updatedAt,
    int? id,
  }) => SavingRecord(
    id: id,
    kind: kind,
    description: description,
    baselineMinor: baseline,
    actualMinor: actual,
    occurredOn: date,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    today: now,
  );
  test('规格样例：新增、编辑和删除后重算', () {
    final records = [
      record(),
      record(kind: DecisionKind.alternative, baseline: 2000, actual: 1200),
      record(kind: DecisionKind.forgone, baseline: null, actual: null),
    ];
    var summary = SavingsSummary.fromRecords(records);
    expect(summary.savedMinor, 2300);
    expect(summary.goodChoices, 3);
    records[0] = record(actual: 2000);
    summary = SavingsSummary.fromRecords(records);
    expect(summary.savedMinor, 1800);
    expect(summary.goodChoices, 3);
    records.removeAt(1);
    summary = SavingsSummary.fromRecords(records);
    expect(summary.savedMinor, 1000);
    expect(summary.goodChoices, 2);
  });
  test('空集合和仅非金额选择', () {
    expect(SavingsSummary.fromRecords([]).savedMinor, 0);
    expect(SavingsSummary.fromRecords([]).goodChoices, 0);
    final summary = SavingsSummary.fromRecords([
      record(kind: DecisionKind.forgone, baseline: null, actual: null),
    ]);
    expect(summary.savedMinor, 0);
    expect(summary.goodChoices, 1);
  });
  test('相同描述不自动去重', () {
    expect(SavingsSummary.fromRecords([record(), record()]).goodChoices, 2);
  });
  test('类型转换重算金额，去除原有金额', () {
    final changed = record(
      kind: DecisionKind.forgone,
      baseline: null,
      actual: null,
    );
    expect(changed.savedMinor, 0);
    expect(record(actual: 0).savedMinor, 3000);
  });
  for (final kind in [DecisionKind.budget, DecisionKind.alternative]) {
    for (final pair in <(int?, int?)>[
      (null, 100),
      (100, null),
      (0, 0),
      (100, 100),
      (100, 101),
      (100, -1),
      (maxMoneyMinor + 1, 0),
      (100, maxMoneyMinor + 1),
    ]) {
      test('拒绝无效金额 $kind $pair', () {
        expect(
          () => record(kind: kind, baseline: pair.$1, actual: pair.$2),
          throwsA(isA<RuleViolation>()),
        );
      });
    }
  }
  test('放弃购买拒绝金额，不能默默折算', () {
    expect(
      () => record(kind: DecisionKind.forgone),
      throwsA(isA<RuleViolation>()),
    );
  });
  for (final text in ['', '   ', '字' * 201]) {
    test('描述边界 ${text.length}', () {
      expect(() => record(description: text), throwsA(isA<RuleViolation>()));
    });
  }
  test('描述去除首尾空白', () {
    expect(record(description: '  小选择  ').description, '小选择');
    expect(record(description: '字' * 200).description.length, 200);
  });
  for (final date in ['2026-10-23', '2026-02-30', '2026-1-01', 'invalid']) {
    test('拒绝无效或未来日期 $date', () {
      expect(() => record(date: date), throwsA(isA<RuleViolation>()));
    });
  }
  test('允许补记、保留UTC时间', () {
    expect(record(date: '2026-01-01').occurredOn, '2026-01-01');
    expect(record().createdAt.isUtc, isTrue);
  });
  test('拒绝错误ID及时间', () {
    expect(() => record(id: 0), throwsA(isA<RuleViolation>()));
    expect(
      () => record(updatedAt: now.subtract(const Duration(seconds: 1))),
      throwsA(isA<RuleViolation>()),
    );
  });
  test('金额格式不经过浮点', () {
    expect(formatMoney(1), '0.01');
    expect(formatMoney(123456789), '1234567.89');
  });
  test('汇总整数上限及溢出保护', () {
    expect(checkedAddMinor(maxAggregateMinor - 1, 1), maxAggregateMinor);
    expect(
      () => checkedAddMinor(maxAggregateMinor, 1),
      throwsA(isA<RuleViolation>()),
    );
    expect(() => checkedAddMinor(-1, 1), throwsA(isA<RuleViolation>()));
    expect(() => checkedAddMinor(1, -1), throwsA(isA<RuleViolation>()));
  });
}
