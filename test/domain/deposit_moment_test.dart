import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/domain/deposit_moment.dart';

void main() {
  test('首次只认真实新增 ID=1，普通记录不冒充首次', () {
    expect(depositMoment(newRecordId: 1), DepositMoment.firstSaving);
    expect(depositMoment(newRecordId: 2), DepositMoment.normal);
  });
  test('过半与达成用整数分判断，优先级完成高于过半和首次', () {
    expect(
      depositMoment(
        newRecordId: 1,
        targetMinor: 101,
        beforeMinor: 0,
        afterMinor: 50,
      ),
      DepositMoment.firstSaving,
    );
    expect(
      depositMoment(
        newRecordId: 2,
        targetMinor: 101,
        beforeMinor: 50,
        afterMinor: 51,
      ),
      DepositMoment.halfway,
    );
    expect(
      depositMoment(
        newRecordId: 1,
        targetMinor: 101,
        beforeMinor: 0,
        afterMinor: 101,
      ),
      DepositMoment.completed,
    );
    expect(
      depositMoment(
        newRecordId: 3,
        targetMinor: 101,
        beforeMinor: 101,
        afterMinor: 102,
      ),
      DepositMoment.normal,
    );
    expect(
      depositMoment(
        newRecordId: 3,
        targetMinor: 100,
        beforeMinor: 50,
        afterMinor: 60,
      ),
      DepositMoment.normal,
    );
  });
  test('进度减少与无目标不误庆祝', () {
    expect(
      depositMoment(
        newRecordId: 3,
        targetMinor: 100,
        beforeMinor: 80,
        afterMinor: 20,
      ),
      DepositMoment.normal,
    );
    expect(depositMoment(newRecordId: 3), DepositMoment.normal);
  });
}
