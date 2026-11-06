import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/domain/pig_growth.dart';

void main() {
  test('全部等级边界由有效数量推导', () {
    for (final entry in {
      0: 1,
      4: 1,
      5: 2,
      14: 2,
      15: 3,
      29: 3,
      30: 4,
      59: 4,
      60: 5,
      600: 5,
    }.entries) {
      expect(PigGrowth(entry.key).level, entry.value);
    }
    expect(() => PigGrowth(-1), throwsArgumentError);
  });
  test('成长进度以本级跨度计算，满级不生成新任务', () {
    expect(PigGrowth(0).fraction, 0);
    expect(PigGrowth(4).remaining, 1);
    expect(PigGrowth(5).fraction, 0);
    expect(PigGrowth(14).fraction, .9);
    expect(PigGrowth(29).remaining, 1);
    expect(PigGrowth(59).remaining, 1);
    expect(PigGrowth(60).fraction, 1);
    expect(PigGrowth(60).nextThreshold, isNull);
  });
  test('只有新增跨级才升级，重读和编辑删除不产生事件', () {
    expect(PigGrowth(4).crossedByNewRecord(5), isTrue);
    expect(PigGrowth(5).crossedByNewRecord(5), isFalse);
    expect(PigGrowth(5).crossedByNewRecord(4), isFalse);
    expect(PigGrowth(5).crossedByNewRecord(6), isFalse);
    expect(PigGrowth(59).crossedByNewRecord(60), isTrue);
    expect(PigGrowth(60).crossedByNewRecord(61), isFalse);
  });
}
