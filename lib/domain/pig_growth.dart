/// 等级只来自当前有效记录数量，不存储经验或等级。
class PigGrowth {
  PigGrowth(this.choices) {
    if (choices < 0) throw ArgumentError.value(choices, 'choices');
  }
  final int choices;
  static const thresholds = [0, 5, 15, 30, 60];
  int get level => thresholds.lastIndexWhere((value) => choices >= value) + 1;
  int get start => thresholds[level - 1];
  int? get nextThreshold =>
      level == thresholds.length ? null : thresholds[level];
  int get remaining => nextThreshold == null ? 0 : nextThreshold! - choices;
  double get fraction =>
      nextThreshold == null ? 1 : (choices - start) / (nextThreshold! - start);
  bool crossedByNewRecord(int nextChoices) =>
      nextChoices == choices + 1 && PigGrowth(nextChoices).level > level;
}

/// 仅存已展示的庆祝，不影响真实成长。claim 必须原子去重。
abstract interface class GrowthCelebrationStore {
  Future<bool> claimGrowthCelebration(int level);
}
