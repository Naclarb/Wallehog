import 'expression_parser.dart';
import 'saving_record.dart';

class WishlistGoal {
  factory WishlistGoal({
    required String name,
    required int targetMinor,
    required int startAfterId,
    int? id,
    String style = 'gift',
    Set<int>? recordIds,
  }) {
    if (name.trim().isEmpty || name.trim().length > 60) {
      throw const RuleViolation('请填写 1–60 字的心愿名称');
    }
    if (targetMinor <= 0 || targetMinor > maxMoneyMinor || startAfterId < 0) {
      throw const RuleViolation('请填写有效的正数目标金额');
    }
    if ((id != null && id <= 0) ||
        !goalStyles.contains(style) ||
        (recordIds != null && recordIds.any((id) => id <= startAfterId))) {
      throw const RuleViolation('心愿样式或记录归属无效');
    }
    return WishlistGoal._(
      name.trim(),
      targetMinor,
      startAfterId,
      id,
      style,
      recordIds == null ? null : Set.unmodifiable(recordIds),
    );
  }
  const WishlistGoal._(
    this.name,
    this.targetMinor,
    this.startAfterId,
    this.id,
    this.style,
    this.recordIds,
  );
  final int? id;
  final String style;
  final Set<int>? recordIds;
  final String name;
  final int targetMinor;
  final int startAfterId;
  int progressMinor(Iterable<SavingRecord> records) =>
      SavingsSummary.fromRecords(
        records.where(
          (r) =>
              r.id != null &&
              (recordIds?.contains(r.id) ?? (r.id! > startAfterId)),
        ),
      ).savedMinor;
  double progressFraction(Iterable<SavingRecord> records) =>
      (progressMinor(records) / targetMinor).clamp(0.0, 1.0);
}

class RecordSnapshot {
  const RecordSnapshot(this.records, this.goal, {this.allGoals});
  final List<SavingRecord> records;
  final WishlistGoal? goal;
  final List<WishlistGoal>? allGoals;
  List<WishlistGoal> get goals =>
      allGoals ?? (goal == null ? const [] : [goal!]);
}

const goalStyles = ['gift', 'ps5', 'headphones', 'camera'];
const goalStyleNames = {
  'gift': '自由心愿',
  'ps5': 'PS5 游戏机',
  'headphones': '一副好耳机',
  'camera': '我的相机',
};
String goalAsset(String style) => style == 'gift'
    ? 'assets/characters/wish-gift-v1.png'
    : 'assets/characters/wish-$style-v1.png';
