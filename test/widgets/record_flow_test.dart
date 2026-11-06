import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/saving_record.dart';
import 'package:wallehog/features/entry/calculator_sheet.dart';
import '../support/memory_repository.dart';

Future<void> reveal(WidgetTester tester, Finder target) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('390×844 首屏包含Goal、金额和底栏Add', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = RecordsController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.createGoal('一副喜欢的耳机', 100000);
    await tester.pumpWidget(WallehogApp(controller: controller));
    await tester.pumpAndSettle();
    for (final key in ['goalCard', 'savedMoney', 'newRecord']) {
      final rect = tester.getRect(find.byKey(Key(key)));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(844));
    }
    expect(find.byKey(const Key('newRecord')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('长目标、大金额和双倍字体保留完整内容且无溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = RecordsController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    final name = List.filled(12, '喜欢的耳机').join();
    await controller.createGoal(name, 999999999);
    final now = DateTime.now();
    await controller.save(
      SavingRecord(
        kind: DecisionKind.quick,
        description: '',
        amountMinor: 999999999,
        occurredOn: dateKey(now),
        createdAt: now,
        updatedAt: now,
        today: now,
      ),
    );
    await tester.pumpWidget(WallehogApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text(name), findsOneWidget);
    expect(tester.widget<Text>(find.text(name)).maxLines, isNull);
    await reveal(tester, find.byKey(const Key('newRecord')));
    expect(find.text('¥9999999.99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('提交成功但读取失败时只重读，不重复写入', (tester) async {
    final repository = _FailReadAfterWrite();
    final controller = RecordsController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(WallehogApp(controller: controller));
    await reveal(tester, find.byKey(const Key('newRecord')));
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expression')), '27');
    await reveal(tester, find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('重试读取已保存记录'), findsOneWidget);
    expect(find.byKey(const Key('depositFeedback')), findsNothing);
    expect(repository.records.length, 1);
    repository.failRead = false;
    await reveal(tester, find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(controller.summary.savedMinor, 2700);
    expect(repository.records.length, 1);
    await tester.pump(const Duration(seconds: 2));
  });
  testWidgets('加号直接计算器，2无需表单，金额/Goal同步', (tester) async {
    final controller = RecordsController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.createGoal('新耳机', 10000);
    await tester.pumpWidget(WallehogApp(controller: controller));
    await reveal(tester, find.byKey(const Key('newRecord')));
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    expect(find.byType(CalculatorSheet), findsOneWidget);
    expect(find.text('选择类型'), findsNothing);
    expect(find.text('既定预算（元）'), findsNothing);
    expect(find.byKey(const Key('optionalNote')), findsNothing);
    await tester.tap(find.byKey(const Key('key_2')));
    await tester.pump();
    expect(find.text('+¥2.00'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(find.byType(CalculatorSheet), findsNothing);
    expect(controller.summary.savedMinor, 200);
    expect(controller.goalProgressMinor, 200);
    expect(find.text('¥2.00'), findsOneWidget);
    expect(find.text('¥2.00 / ¥100.00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
  testWidgets('27和算式实时结果，零/负数/无效不能保存', (tester) async {
    final controller = RecordsController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(WallehogApp(controller: controller));
    await reveal(tester, find.byKey(const Key('newRecord')));
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    for (final input in ['0', '-2', '1/0', '1+', '']) {
      await tester.enterText(find.byKey(const Key('expression')), input);
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('confirmSaving')))
            .onPressed,
        isNull,
      );
    }
    for (final entry in {
      '27': '+¥27.00',
      '30-12-10-5': '+¥3.00',
      '2+3*4': '+¥14.00',
    }.entries) {
      await tester.enterText(find.byKey(const Key('expression')), entry.key);
      await tester.pump();
      expect(find.text(entry.value), findsOneWidget);
    }
  });
  testWidgets('写入失败保留输入并可以重试，不要求重新填写', (tester) async {
    final repository = MemoryRepository();
    final controller = RecordsController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(WallehogApp(controller: controller));
    await reveal(tester, find.byKey(const Key('newRecord')));
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expression')), '27');
    repository.fail = true;
    await reveal(tester, find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saveError')), findsOneWidget);
    expect(find.byKey(const Key('depositFeedback')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('expression')))
          .controller!
          .text,
      '27',
    );
    repository.fail = false;
    await reveal(tester, find.byKey(const Key('confirmSaving')));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    expect(controller.summary.savedMinor, 2700);
    expect(controller.summary.goodChoices, 1);
    await tester.pump(const Duration(seconds: 2));
  });
  testWidgets('首页创建Goal，未创建不伪造目标', (tester) async {
    final controller = RecordsController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(WallehogApp(controller: controller));
    expect(find.text('给小猪一个期待'), findsOneWidget);
    await tester.tap(find.byKey(const Key('editGoal')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goalNameInput')), '相机');
    await tester.enterText(find.byKey(const Key('goalTargetInput')), '100');
    await tester.tap(find.byKey(const Key('saveGoal')));
    await tester.pumpAndSettle();
    expect(controller.goal!.name, '相机');
    expect(controller.goalProgressMinor, 0);
  });
  testWidgets('读取失败不伪造金额', (tester) async {
    final repository = MemoryRepository()..fail = true;
    final controller = RecordsController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(WallehogApp(controller: controller));
    expect(find.byKey(const Key('savedMoney')), findsNothing);
    expect(find.text('重新读取'), findsOneWidget);
  });
  testWidgets('窄屏大字体首页与计算器无溢出', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = RecordsController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(WallehogApp(controller: controller));
    await reveal(tester, find.byKey(const Key('newRecord')));
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _FailReadAfterWrite extends MemoryRepository {
  @override
  Future<void> save(SavingRecord record) async {
    await super.save(record);
    failRead = true;
  }
}
