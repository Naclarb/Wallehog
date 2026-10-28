import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/domain/encouragement.dart';
import 'package:wallehog/domain/deposit_moment.dart';
import 'package:wallehog/shared/coin_deposit_feedback.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import '../support/memory_repository.dart';

void main() {
  test('相邻鼓励语不重复', () {
    final lines = Encouragements(random: Random(1));
    for (final scene in EncouragementScene.values) {
      var previous = lines.pick(scene);
      for (var i = 0; i < 20; i++) {
        final next = lines.pick(scene);
        expect(next, isNot(previous));
        previous = next;
      }
    }
  });
  for (final reduced in [false, true]) {
    testWidgets('首次、过半、达成只在保存后回应，减少动画=$reduced', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repo = MemoryRepository();
      final c = RecordsController(repo);
      addTearDown(c.dispose);
      await c.load();
      await c.createGoal('心愿', 10000);
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      final moments = [
        DepositMoment.firstSaving,
        DepositMoment.halfway,
        DepositMoment.completed,
      ];
      final amounts = ['27', '23', '50'];
      for (var i = 0; i < amounts.length; i++) {
        await tester.tap(find.byKey(const Key('newRecord')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('depositFeedback')), findsNothing);
        await tester.enterText(find.byKey(const Key('expression')), amounts[i]);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
        await tester.tap(find.byKey(const Key('confirmSaving')));
        await tester.pumpAndSettle();
        final feedback = tester.widget<CoinDepositFeedback>(
          find.byType(CoinDepositFeedback),
        );
        expect(feedback.moment, moments[i]);
        expect(find.text(moments[i].label!), findsOneWidget);
        if (reduced) {
          expect(find.byKey(const Key('momentGlow')), findsNothing);
          expect(find.byKey(const Key('depositCoin')), findsNothing);
        }
      }
      expect(c.summary.savedMinor, 10000);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('depositFeedback')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!const bool.fromEnvironment('CAPTURE_FEEDBACK')) return;
    final chinese = FontLoader('Roboto');
    chinese.addFont(
      Future.value(
        ByteData.sublistView(
          await File(
            const String.fromEnvironment('CAPTURE_FONT_PATH'),
          ).readAsBytes(),
        ),
      ),
    );
    await chinese.load();
    final nunito = FontLoader('Nunito');
    nunito.addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await nunito.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('金币先飞入投币口，随后小猪轻跳，鼓励语显现', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoinDepositFeedback(message: '收到啦', amount: '+¥27.00'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('depositCoin')), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(of: find.text('收到啦'), matching: find.byType(Opacity))
                .first,
          )
          .opacity,
      0,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('depositCoin')), findsNothing);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(of: find.text('收到啦'), matching: find.byType(Opacity))
                .first,
          )
          .opacity,
      greaterThan(0),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test('台词场景优先级和本地库', () {
    expect(
      encouragementScene(completed: true, fraction: 1, returning: true),
      EncouragementScene.completed,
    );
    expect(
      encouragementScene(completed: false, fraction: .9, returning: true),
      EncouragementScene.welcomeBack,
    );
    expect(
      encouragementScene(completed: false, fraction: .8, returning: false),
      EncouragementScene.nearGoal,
    );
    expect(
      encouragementScene(completed: false, fraction: 1, returning: false),
      EncouragementScene.normal,
    );
    for (final scene in EncouragementScene.values) {
      expect(Encouragements(random: Random(1)).pick(scene), isNotEmpty);
    }
  });
  testWidgets('减少动画仍显示金额和台词且可安全释放', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(
            body: CoinDepositFeedback(message: '小猪收到！', amount: '+¥27.00'),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('depositCoin')), findsNothing);
    expect(find.text('已记录 +¥27.00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('飞行中退出正确释放控制器', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoinDepositFeedback(message: '收到啦', amount: '+¥27.00'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('depositCoin')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
  testWidgets('真实录入27、快速重复点击、反馈逐帧与退出', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = MemoryRepository();
    final controller = RecordsController(repo);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.createGoal('一副喜欢的耳机', 10000);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('capture'),
        child: WallehogApp(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expression')), '27');
    await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.tap(
      find.byKey(const Key('confirmSaving')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(repo.records.length, 1);
    expect(controller.summary.savedMinor, 2700);
    expect(controller.goalProgressMinor, 2700);
    for (
      var frame = 0;
      frame < 60 && find.byKey(const Key('depositFeedback')).evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('depositFeedback')), findsOneWidget);
    if (const bool.fromEnvironment('CAPTURE_FEEDBACK')) {
      await expectLater(
        find.byKey(const Key('capture')),
        matchesGoldenFile('../../docs/screenshots/freeze17-deposit-300ms.png'),
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
    if (const bool.fromEnvironment('CAPTURE_FEEDBACK')) {
      await expectLater(
        find.byKey(const Key('capture')),
        matchesGoldenFile('../../docs/screenshots/freeze17-deposit-400ms.png'),
      );
    }
    await tester.pump(const Duration(milliseconds: 250));
    if (const bool.fromEnvironment('CAPTURE_FEEDBACK')) {
      await expectLater(
        find.byKey(const Key('capture')),
        matchesGoldenFile('../../docs/screenshots/freeze17-deposit-650ms.png'),
      );
    }
    expect(find.byKey(const Key('depositCoin')), findsNothing);
    // 上次反馈仍在时可继续保存，旧提示直接替换。
    await tester.tap(find.byKey(const Key('newRecord')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(const Key('expression')), '27');
    await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('confirmSaving')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(repo.records.length, 2);
    expect(controller.goalProgressMinor, 5400);
    for (
      var frame = 0;
      frame < 60 && find.byKey(const Key('depositFeedback')).evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byKey(const Key('depositFeedback')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('depositFeedback')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
