/// 仅描述已提交的新记录反馈，不改变金额、成长或持久化状态。
enum DepositMoment { normal, firstSaving, halfway, completed }

DepositMoment depositMoment({
  required int newRecordId,
  int? targetMinor,
  int beforeMinor = 0,
  int afterMinor = 0,
}) {
  if (targetMinor != null && targetMinor > 0 && afterMinor > beforeMinor) {
    if (beforeMinor < targetMinor && afterMinor >= targetMinor) {
      return DepositMoment.completed;
    }
    if (beforeMinor * 2 < targetMinor && afterMinor * 2 >= targetMinor) {
      return DepositMoment.halfway;
    }
  }
  return newRecordId == 1 ? DepositMoment.firstSaving : DepositMoment.normal;
}

extension DepositMomentLabel on DepositMoment {
  String? get label => switch (this) {
    DepositMoment.normal => null,
    DepositMoment.firstSaving => '第一枚金币，收到啦',
    DepositMoment.halfway => '心愿已经走过一半',
    DepositMoment.completed => '心愿进度达成！',
  };
}
