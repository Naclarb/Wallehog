import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/application/home_widget_service.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import '../support/memory_repository.dart';
import '../support/fault_injecting_repository.dart';

void main() {
  late MemoryRepository repository;
  late FaultInjectingRepository faults;
  late RecordsController controller;
  late HomeWidgetService service;
  Map<Object?, Object?> request({
    String token = 'widget:test',
    int amount = 1234,
    int? goalId,
  }) => {
    'token': token,
    'amountMinor': amount,
    'goalId': goalId,
    'date': dateKey(DateTime.now()),
  };

  setUp(() async {
    repository = MemoryRepository();
    faults = FaultInjectingRepository(repository);
    controller = RecordsController(faults);
    service = HomeWidgetService(controller);
    await controller.load();
  });

  test(
    'saves integer minor units into the current wish, retry counts once',
    () async {
      await controller.createGoal('Camera', 20000, style: 'camera');
      final input = request(goalId: controller.goal!.id);
      expect((await service.submit(input))['status'], 'saved');
      expect((await service.submit(input))['status'], 'saved');
      expect(controller.records.single.savedMinor, 1234);
      expect(controller.summary.goodChoices, 1);
      expect(service.snapshot()['progressMinor'], 1234);
      expect(repository.assignments.values.single, controller.goal!.id);
    },
  );

  test('home wish changes require review before committing', () async {
    await controller.createGoal('First', 10000);
    final old = controller.goal!.id;
    await controller.createGoal('Second', 10000);
    final result = await service.submit(request(goalId: old));
    expect(result['status'], 'changed');
    expect(result['goalId'], controller.goal!.id);
    expect(controller.records, isEmpty);
    expect(
      (await service.submit(request(goalId: controller.goal!.id)))['status'],
      'saved',
    );
  });

  test('unbound entry works when no wish exists', () async {
    expect((await service.submit(request()))['status'], 'saved');
    expect(repository.assignments, isEmpty);
    expect(controller.summary.savedMinor, 1234);
  });

  test(
    'write failure retains a retryable request without adding a record',
    () async {
      faults.failBeforeWrite = true;
      expect((await service.submit(request()))['status'], 'unavailable');
      expect(repository.records, isEmpty);
      faults.failBeforeWrite = false;
      expect((await service.submit(request()))['status'], 'saved');
      expect(repository.records, hasLength(1));
    },
  );

  test(
    'committed save with snapshot failure recovers without replay',
    () async {
      faults.failSnapshotAfterWrite = true;
      expect((await service.submit(request()))['status'], 'unavailable');
      expect(controller.needsRecovery, isTrue);
      expect(repository.records, hasLength(1));
      faults.failSnapshotAfterWrite = false;
      faults.failSnapshot = false;
      expect((await service.submit(request()))['status'], 'saved');
      expect(faults.commits['save'], 1);
      expect(controller.summary.goodChoices, 1);
    },
  );

  test(
    'retry after process restart and wish switch acknowledges the old save',
    () async {
      await controller.createGoal('First', 10000);
      final input = request(goalId: controller.goal!.id);
      await service.submit(input);
      await controller.createGoal('Second', 10000);
      final reopened = RecordsController(repository);
      await reopened.load();
      final response = await HomeWidgetService(reopened).submit(input);
      expect(response['status'], 'saved');
      expect(repository.records, hasLength(1));
      expect(response['progressMinor'], 0);
    },
  );

  test('busy controller refuses another write', () async {
    faults.snapshotGate = Completer<void>();
    final loading = controller.load();
    expect((await service.submit(request()))['status'], 'unavailable');
    expect(repository.records, isEmpty);
    faults.snapshotGate!.complete();
    await loading;
  });

  test('invalid and future amounts/dates do not enter storage', () async {
    for (final amount in [0, -1, 1000000000]) {
      await expectLater(
        service.submit(request(amount: amount)),
        throwsException,
      );
    }
    final future = request()
      ..['date'] = dateKey(DateTime.now().add(const Duration(days: 2)));
    await expectLater(service.submit(future), throwsException);
    await expectLater(
      service.submit(request()..['token'] = 'other'),
      throwsException,
    );
    expect(repository.records, isEmpty);
  });
}
