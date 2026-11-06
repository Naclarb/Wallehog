import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import '../support/fault_injecting_repository.dart';
import '../support/memory_repository.dart';

void main() {
  Future<(RecordsController, FaultInjectingRepository)> mount(
    WidgetTester tester, {
    bool legacy = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final memory = MemoryRepository();
    final repo = FaultInjectingRepository(memory);
    final c = RecordsController(repo);
    addTearDown(c.dispose);
    await c.load();
    await c.createGoal('原心愿', 10000);
    if (legacy) {
      final now = DateTime.now();
      await c.save(
        SavingRecord(
          kind: DecisionKind.forgone,
          description: '原选择',
          occurredOn: dateKey(now),
          createdAt: now,
          updatedAt: now,
          today: now,
        ),
      );
    }
    await tester.pumpWidget(WallehogApp(controller: c));
    await tester.pumpAndSettle();
    return (c, repo);
  }

  for (final committed in [false, true]) {
    testWidgets('非金额旧记录编辑保留输入，提交=$committed 时选择安全重试方式', (tester) async {
      final (c, repo) = await mount(tester, legacy: true);
      final original = c.records.single;
      final row = find.byKey(ValueKey('swipeSaving_${original.id}'));
      await tester.ensureVisible(row);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      // EntryPage 的实际表单 key，保留原记录身份和归属。
      await tester.enterText(
        find.byKey(const Key('description')),
        '重试后也保留这段编辑',
      );
      repo.failBeforeWrite = !committed;
      repo.failSnapshotAfterWrite = committed;
      await tester.ensureVisible(find.byKey(const Key('saveRecord')));
      await tester.tap(find.byKey(const Key('saveRecord')));
      await tester.pumpAndSettle();
      expect(find.text('重试后也保留这段编辑'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('description'))).enabled,
        !committed,
      );
      final writes = repo.commits['save']!;
      repo.failBeforeWrite = false;
      repo.failSnapshotAfterWrite = false;
      repo.failSnapshot = false;
      if (committed) {
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('saveRecord')))
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('重新读取并返回，确认记录后再继续'));
      } else {
        expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('saveRecord')))
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byKey(const Key('saveRecord')));
      }
      await tester.pumpAndSettle();
      expect(c.records.single.description, '重试后也保留这段编辑');
      expect(c.records.single.id, original.id);
      expect(c.goal!.recordIds, {original.id});
      expect(c.summary.goodChoices, 1);
      expect(repo.commits['save'], writes + (committed ? 0 : 1));
    });
  }

  testWidgets('创建心愿提交后关闭弹窗：帮助页仍能重读，禁止旧快照录入', (tester) async {
    final (c, repo) = await mount(tester);
    await tester.tap(find.byKey(const Key('addGoal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goalNameInput')), '新心愿');
    await tester.enterText(find.byKey(const Key('goalTargetInput')), '200');
    repo.failSnapshotAfterWrite = true;
    await tester.ensureVisible(find.byKey(const Key('saveGoal')));
    await tester.tap(find.byKey(const Key('saveGoal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<IconButton>(find.byKey(const Key('newRecord'))).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('helpTab')));
    await tester.pumpAndSettle();
    expect(find.text('重新读取'), findsOneWidget);
    await tester.tap(find.text('重新读取'));
    await tester.pumpAndSettle();
    expect(c.loaded, isFalse);
    repo.failSnapshot = false;
    repo.failSnapshotAfterWrite = false;
    final writes = Map.of(repo.commits);
    await tester.tap(find.text('重新读取'));
    await tester.pumpAndSettle();
    expect(c.goal!.name, '新心愿');
    expect(repo.commits, writes);
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expression')), '2');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(c.error, isNull);
    expect(c.records, hasLength(1));
    expect(c.goal!.recordIds, {c.records.single.id});
    expect(c.goalProgressMinor, 200);
  });
}
