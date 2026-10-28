import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import '../support/memory_repository.dart';

void main() {
  test('切换心愿已提交但重读失败时暂停录入，重读后选中一致', () async {
    final repository = MemoryRepository();
    final controller = RecordsController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.createGoal('PS5', 400000, style: 'ps5');
    final first = controller.goal!.id!;
    await controller.createGoal('耳机', 100000, style: 'headphones');
    repository.failRead = true;
    expect(await controller.selectGoal(first), isFalse);
    expect(controller.writeCommitted, isTrue);
    expect(controller.loaded, isFalse);
    repository.failRead = false;
    expect(await controller.load(), isTrue);
    expect(controller.goal!.id, first);
    expect(controller.loaded, isTrue);
  });
  final now = DateTime.now();
  SavingRecord record(int id, {bool forgone = false, int actual = 1000}) =>
      SavingRecord(
        id: id,
        kind: forgone ? DecisionKind.forgone : DecisionKind.budget,
        description: '小选择',
        baselineMinor: forgone ? null : 3000,
        actualMinor: forgone ? null : actual,
        occurredOn: dateKey(now),
        createdAt: now,
        updatedAt: now,
        today: now,
      );
  test('所有修改均刷新汇总，类型修改保持次数', () async {
    final repository = MemoryRepository();
    final controller = RecordsController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.loaded, isTrue);
    await controller.save(record(1));
    await controller.save(record(2, forgone: true));
    expect(controller.summary.savedMinor, 2000);
    expect(controller.summary.goodChoices, 2);
    await controller.save(record(1, actual: 2500));
    expect(controller.summary.savedMinor, 500);
    await controller.save(record(1, forgone: true));
    expect(controller.summary.savedMinor, 0);
    expect(controller.summary.goodChoices, 2);
    await controller.delete(1);
    expect(controller.summary.goodChoices, 1);
    await controller.delete(2);
    expect(controller.summary.goodChoices, 0);
  });
  test('失败不显示伪成功或空数据，重读可恢复', () async {
    final repository = MemoryRepository();
    final controller = RecordsController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.save(record(1));
    repository.fail = true;
    expect(await controller.save(record(2)), isFalse);
    expect(controller.summary.goodChoices, 1);
    expect(controller.loaded, isTrue);
    expect(controller.error, isNotNull);
    expect(controller.busy, isFalse);
    repository.fail = false;
    expect(await controller.load(), isTrue);
    expect(controller.summary.goodChoices, 1);
  });
  test('并发点击只执行一次写入', () async {
    final repository = _DelayedRepository();
    final controller = RecordsController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    final first = controller.save(record(1));
    expect(await controller.save(record(2)), isFalse);
    repository.gate.complete();
    expect(await first, isTrue);
    expect(controller.summary.goodChoices, 1);
  });
}

class _DelayedRepository extends MemoryRepository {
  final gate = Completer<void>();
  @override
  Future<void> save(SavingRecord record) async {
    await gate.future;
    await super.save(record);
  }
}
