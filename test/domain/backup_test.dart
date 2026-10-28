import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/domain/backup.dart';
import 'package:wallehog/domain/expression_parser.dart';

Map<String, Object?> fixture() => {
  'format': 'wallehog',
  'version': 1,
  'currency': 'CNY',
  'exportedAt': '2026-01-01T00:00:00.000Z',
  'highWater': 9,
  'records': [
    {
      'id': 2,
      'kind': 'quick',
      'description': '',
      'amountMinor': 200,
      'baselineMinor': null,
      'actualMinor': null,
      'clientToken': 'unique',
      'occurredOn': '2020-01-01',
      'createdAt': '2020-01-01T00:00:00.000Z',
      'updatedAt': '2020-01-01T00:00:00.000Z',
    },
  ],
  'goal': {'name': '旅行', 'targetMinor': 1000, 'startAfterId': 1},
};

void main() {
  test('拒绝重复请求身份和无效日历时间，历史日期不受设备今天限制', () {
    final value = fixture();
    final rows = value['records'] as List;
    rows.add(Map<String, Object?>.from(rows.single as Map)..['id'] = 3);
    expect(
      () => SavingsBackup.decode(jsonEncode(value)),
      throwsA(isA<RuleViolation>()),
    );
    rows.removeLast();
    (rows.single as Map)['occurredOn'] = '2999-01-01';
    expect(
      SavingsBackup.decode(
        jsonEncode(value),
        today: DateTime(2026),
      ).records.single.occurredOn,
      '2999-01-01',
    );
    (rows.single as Map)['occurredOn'] = '2020-01-01';
    value['exportedAt'] = '2026-02-30T00:00:00.000Z';
    expect(
      () => SavingsBackup.decode(jsonEncode(value)),
      throwsA(isA<RuleViolation>()),
    );
  });
  test('兼容旧比较记录与非金额好选择，不将其改成快速记录', () {
    final value = fixture();
    final rows = value['records'] as List;
    final row = rows.single as Map;
    row['kind'] = 'budget';
    row['description'] = '自带午餐';
    row['amountMinor'] = null;
    row['baselineMinor'] = 3000;
    row['actualMinor'] = 2000;
    var backup = SavingsBackup.decode(jsonEncode(value));
    expect(backup.records.single.savedMinor, 1000);
    row['kind'] = 'forgone';
    row['baselineMinor'] = null;
    row['actualMinor'] = null;
    backup = SavingsBackup.decode(jsonEncode(value));
    expect(backup.summary.savedMinor, 0);
    expect(backup.summary.goodChoices, 1);
    expect(() => backup.records.clear(), throwsUnsupportedError);
  });
  test('备份往返保留删除后的高水位、请求身份和目标边界', () {
    final backup = SavingsBackup.decode(jsonEncode(fixture()));
    final copy = SavingsBackup.decode(backup.encode());
    expect(copy.highWater, 9);
    expect(copy.records.single.clientToken, 'unique');
    expect(copy.goal!.progressMinor(copy.records), 200);
  });
  for (final field in ['version', 'currency', 'highWater']) {
    test('拒绝无效 $field', () {
      final value = fixture();
      value[field] = switch (field) {
        'version' => 99,
        'currency' => 'USD',
        _ => 0,
      };
      expect(
        () => SavingsBackup.decode(jsonEncode(value)),
        throwsA(isA<RuleViolation>()),
      );
    });
  }
  test('拒绝重复 ID、非整数金额及越界目标', () {
    final value = fixture();
    final rows = value['records'] as List;
    rows.add(Map<String, Object?>.from(rows.single as Map));
    expect(
      () => SavingsBackup.decode(jsonEncode(value)),
      throwsA(isA<RuleViolation>()),
    );
    rows.removeLast();
    (rows.single as Map)['amountMinor'] = 2.5;
    expect(
      () => SavingsBackup.decode(jsonEncode(value)),
      throwsA(isA<RuleViolation>()),
    );
    (rows.single as Map)['amountMinor'] = 200;
    (value['goal'] as Map)['startAfterId'] = 10;
    expect(
      () => SavingsBackup.decode(jsonEncode(value)),
      throwsA(isA<RuleViolation>()),
    );
  });
  test('拒绝损坏 JSON、无时区时间、超大文件', () {
    expect(() => SavingsBackup.decode('{'), throwsA(isA<RuleViolation>()));
    final value = fixture()..['exportedAt'] = '2020-01-01';
    expect(
      () => SavingsBackup.decode(jsonEncode(value)),
      throwsA(isA<RuleViolation>()),
    );
    expect(
      () => SavingsBackup.decode(' ' * (maxBackupBytes + 1)),
      throwsA(isA<RuleViolation>()),
    );
  });
}
