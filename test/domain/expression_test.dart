import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/domain/expression_parser.dart';

void main() {
  group('精确金额表达式', () {
    final cases = <String, int>{
      '2 + 3 * 4': 1400,
      '(2 + 3) * 4': 2000,
      '20 / 2 / 2': 500,
      '10 - 3 - 2': 500,
      '-(-2) + +3': 500,
      '0.1 + 0.2': 30,
      '1 / 3': 33,
      '0.005': 1,
      '0.0049': 0,
      '9999999.99': 999999999,
      '0': 0,
      ' 2 * (3 + 4) ': 1400,
    };
    for (final entry in cases.entries) {
      test(entry.key, () => expect(evaluateMoney(entry.key), entry.value));
    }
    for (final input in [
      '',
      ' ',
      '1/0',
      '1/(2-2)',
      '(1+2',
      '1+2)',
      '1 2',
      '2(3)',
      '1+',
      '.',
      '1..2',
      '1e2',
      '1,000',
      'print(1)',
      '１２',
      '-0.001',
      '-1',
      '10000000',
      '*' * 129,
      '${'(' * 33}1${')' * 33}',
    ]) {
      test('拒绝 $input', () {
        expect(() => evaluateMoney(input), throwsA(isA<RuleViolation>()));
      });
    }
    test('支持32层括号边界', () {
      expect(evaluateMoney('${'(' * 32}1${')' * 32}'), 100);
    });
    test('舍入只在最终字段发生', () {
      expect(evaluateMoney('1 / 3 * 3'), 100);
    });
  });
}
