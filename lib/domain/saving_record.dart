import 'expression_parser.dart';

enum DecisionKind { quick, budget, alternative, forgone }

class SavingRecord {
  factory SavingRecord({
    int? id,
    required DecisionKind kind,
    required String description,
    int? baselineMinor,
    int? actualMinor,
    int? amountMinor,
    String? clientToken,
    required String occurredOn,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime today,
  }) => SavingRecord._validated(
    id: id,
    kind: kind,
    description: description,
    baselineMinor: baselineMinor,
    actualMinor: actualMinor,
    amountMinor: amountMinor,
    clientToken: clientToken,
    occurredOn: occurredOn,
    createdAt: createdAt,
    updatedAt: updatedAt,
    today: today,
  );

  /// 历史解码保留所有数据不变量，但不以当前设备日期否定已保存的日期。
  factory SavingRecord.fromStorage({
    int? id,
    required DecisionKind kind,
    required String description,
    int? baselineMinor,
    int? actualMinor,
    int? amountMinor,
    String? clientToken,
    required String occurredOn,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => SavingRecord._validated(
    id: id,
    kind: kind,
    description: description,
    baselineMinor: baselineMinor,
    actualMinor: actualMinor,
    amountMinor: amountMinor,
    clientToken: clientToken,
    occurredOn: occurredOn,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory SavingRecord._validated({
    int? id,
    required DecisionKind kind,
    required String description,
    int? baselineMinor,
    int? actualMinor,
    int? amountMinor,
    String? clientToken,
    required String occurredOn,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? today,
  }) {
    final text = description.trim();
    if ((kind != DecisionKind.quick && text.isEmpty) || text.length > 200) {
      throw const RuleViolation('请用 1–200 个字符描述这个选择');
    }
    if (id != null && id <= 0) throw const RuleViolation('记录编号无效');
    final date = DateTime.tryParse(occurredOn);
    final cutoff = today == null
        ? null
        : DateTime(today.year, today.month, today.day);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(occurredOn) ||
        date == null ||
        dateKey(date) != occurredOn ||
        (cutoff != null && date.isAfter(cutoff))) {
      throw const RuleViolation('请选择有效的发生日期，不能晚于今天');
    }
    if (updatedAt.isBefore(createdAt)) {
      throw const RuleViolation('修改时间不能早于创建时间');
    }
    if (kind == DecisionKind.quick) {
      if (amountMinor == null ||
          amountMinor <= 0 ||
          amountMinor > maxMoneyMinor ||
          baselineMinor != null ||
          actualMinor != null) {
        throw const RuleViolation('请输入大于零的节省金额');
      }
    } else if (amountMinor != null) {
      throw const RuleViolation('旧类型不能直接指定节省金额');
    } else if (kind == DecisionKind.forgone) {
      if (baselineMinor != null || actualMinor != null) {
        throw const RuleViolation('放弃购买只计好选择，不记录金额');
      }
    } else {
      if (baselineMinor == null ||
          actualMinor == null ||
          baselineMinor <= 0 ||
          actualMinor < 0 ||
          baselineMinor > maxMoneyMinor ||
          actualMinor > maxMoneyMinor ||
          baselineMinor <= actualMinor) {
        throw const RuleViolation('比较基准须大于实际支出；金额必须在有效范围内');
      }
    }
    return SavingRecord._(
      id,
      kind,
      text,
      baselineMinor,
      actualMinor,
      occurredOn,
      createdAt.toUtc(),
      updatedAt.toUtc(),
      amountMinor,
      clientToken,
    );
  }
  const SavingRecord._(
    this.id,
    this.kind,
    this.description,
    this.baselineMinor,
    this.actualMinor,
    this.occurredOn,
    this.createdAt,
    this.updatedAt,
    this.amountMinor,
    this.clientToken,
  );
  final int? id;
  final DecisionKind kind;
  final String description;
  final int? baselineMinor;
  final int? actualMinor;
  final String occurredOn;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? amountMinor;
  final String? clientToken;

  /// 输入的新日期必须不晚于今天；编辑时可原样保留已保存的日期。
  void validateInputDate(DateTime today, {String? originalOccurredOn}) {
    if (occurredOn == originalOccurredOn) return;
    if (DateTime.parse(
      occurredOn,
    ).isAfter(DateTime(today.year, today.month, today.day))) {
      throw const RuleViolation('请选择有效的发生日期，不能晚于今天');
    }
  }

  String get displayTitle => description.isEmpty ? '存下一个小确幸' : description;
  int get savedMinor => kind == DecisionKind.quick
      ? amountMinor!
      : kind == DecisionKind.forgone
      ? 0
      : baselineMinor! - actualMinor!;
}

String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

class SavingsSummary {
  const SavingsSummary(this.savedMinor, this.goodChoices);
  factory SavingsSummary.fromRecords(Iterable<SavingRecord> records) {
    var total = 0;
    var count = 0;
    for (final record in records) {
      total = checkedAddMinor(total, record.savedMinor);
      count++;
    }
    return SavingsSummary(total, count);
  }
  final int savedMinor;
  final int goodChoices;
}

/// 使用 BigInt 检查边界，再转回 Android/SQLite 的有符号 64 位整数。
int checkedAddMinor(int current, int addition) {
  if (current < 0 || addition < 0) {
    throw const RuleViolation('累计金额不能为负数');
  }
  final total = BigInt.from(current) + BigInt.from(addition);
  if (total > BigInt.from(maxAggregateMinor)) {
    throw const RuleViolation('累计金额超出本地存储范围');
  }
  return total.toInt();
}
