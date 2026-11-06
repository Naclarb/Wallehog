/// 可展示给用户的输入错误；领域代码不依赖 Flutter。
class RuleViolation implements Exception {
  const RuleViolation(this.message);
  final String message;
  @override
  String toString() => message;
}

const maxMoneyMinor = 999999999;
const maxAggregateMinor = 9223372036854775807;

/// 只接受十进制数和四则运算；中间值使用精确有理数。
int evaluateMoney(String source) {
  if (source.isEmpty || source.length > 128) {
    throw const RuleViolation('请输入金额算式，最多 128 个字符');
  }
  final value = _Parser(source).parse();
  if (value.n.isNegative) {
    throw const RuleViolation('金额不能为负数');
  }
  final scaled = value.n * BigInt.from(100);
  final rounded = (scaled * BigInt.two + value.d) ~/ (value.d * BigInt.two);
  if (rounded > BigInt.from(maxMoneyMinor)) {
    throw const RuleViolation('单项金额不能超过 9,999,999.99 元');
  }
  return rounded.toInt();
}

String formatMoney(int minor) =>
    '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';

class _Rational {
  factory _Rational(BigInt n, BigInt d) {
    if (d == BigInt.zero) throw const RuleViolation('不能除以零');
    if (n.bitLength > 4096 || d.bitLength > 4096) {
      throw const RuleViolation('算式中间结果过大，请简化');
    }
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final gcd = n.gcd(d);
    return _Rational._(n ~/ gcd, d ~/ gcd);
  }
  const _Rational._(this.n, this.d);
  final BigInt n;
  final BigInt d;
  _Rational operator +(_Rational b) => _Rational(n * b.d + b.n * d, d * b.d);
  _Rational operator -(_Rational b) => _Rational(n * b.d - b.n * d, d * b.d);
  _Rational operator *(_Rational b) => _Rational(n * b.n, d * b.d);
  _Rational operator /(_Rational b) => _Rational(n * b.d, d * b.n);
}

class _Parser {
  _Parser(this.source);
  final String source;
  int pos = 0;
  int depth = 0;
  void space() {
    while (pos < source.length && source[pos] == ' ') {
      pos++;
    }
  }

  bool take(String token) {
    space();
    if (pos < source.length && source[pos] == token) {
      pos++;
      return true;
    }
    return false;
  }

  _Rational parse() {
    final value = expression();
    space();
    if (pos != source.length) throw const RuleViolation('算式包含不支持的字符或缺少运算符');
    return value;
  }

  _Rational expression() {
    var value = term();
    while (true) {
      if (take('+')) {
        value = value + term();
      } else if (take('-')) {
        value = value - term();
      } else {
        return value;
      }
    }
  }

  _Rational term() {
    var value = unary();
    while (true) {
      if (take('*')) {
        value = value * unary();
      } else if (take('/')) {
        value = value / unary();
      } else {
        return value;
      }
    }
  }

  _Rational unary() {
    var negative = false;
    while (true) {
      if (take('+')) {
        continue;
      }
      if (take('-')) {
        negative = !negative;
        continue;
      }
      break;
    }
    final value = primary();
    return negative ? _Rational(-value.n, value.d) : value;
  }

  _Rational primary() {
    if (take('(')) {
      if (++depth > 32) throw const RuleViolation('括号最多嵌套 32 层');
      final value = expression();
      if (!take(')')) throw const RuleViolation('请补全右括号');
      depth--;
      return value;
    }
    space();
    final start = pos;
    while (pos < source.length && _digit(source.codeUnitAt(pos))) {
      pos++;
    }
    if (start == pos) {
      throw const RuleViolation('请输入有效数字，如 12.50 或 (20 + 10) / 2');
    }
    var decimals = 0;
    if (pos < source.length && source[pos] == '.') {
      pos++;
      final fractionalStart = pos;
      while (pos < source.length && _digit(source.codeUnitAt(pos))) {
        pos++;
      }
      decimals = pos - fractionalStart;
      if (decimals == 0) throw const RuleViolation('小数点后需要数字');
    }
    final digits = source.substring(start, pos).replaceAll('.', '');
    return _Rational(BigInt.parse(digits), BigInt.from(10).pow(decimals));
  }

  bool _digit(int c) => c >= 48 && c <= 57;
}
