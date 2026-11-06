import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/shared/coin_deposit_feedback.dart';
import 'package:wallehog/shared/pig_character.dart';
import '../support/memory_repository.dart';
import '../data/pig_growth_repository_test.dart' show quick;

void main() {
  testWidgets('跨级仅庆祝一次，编辑删除实时回退，重建和再跨越不重播', (tester) async {
    final repo = MemoryRepository();
    final c = RecordsController(repo);
    addTearDown(c.dispose);
    await c.load();
    for (var i = 0; i < 4; i++) {
      await c.save(quick(1));
    }
    await tester.pumpWidget(WallehogApp(controller: c));
    await tester.pumpAndSettle();
    Future<void> add() async {
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expression')), '27');
      await tester.ensureVisible(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
    }

    await add();
    expect(find.byKey(const Key('levelUpCelebration')), findsOneWidget);
    expect(find.text('升级啦！Lv.2'), findsOneWidget);
    final record = c.records.first;
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await c.save(quick(999999999, previous: record));
    await tester.pumpAndSettle();
    expect(c.summary.goodChoices, 5);
    expect(find.byKey(const Key('levelUpCelebration')), findsNothing);
    await c.delete(record.id!);
    await tester.tap(find.byKey(const Key('pigRoomTab')));
    await tester.pumpAndSettle();
    expect(find.text('Lv.1'), findsOneWidget);
    await c.save(quick(1));
    await tester.pumpAndSettle();
    expect(find.text('Lv.2'), findsOneWidget);
    expect(find.byKey(const Key('levelUpCelebration')), findsNothing);
    await c.delete(c.records.first.id!);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.pumpWidget(const SizedBox());
    final reopened = RecordsController(repo);
    addTearDown(reopened.dispose);
    await reopened.load();
    await tester.pumpWidget(WallehogApp(controller: reopened));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('depositFeedback')), findsNothing);
    await add();
    expect(reopened.summary.goodChoices, 5);
    expect(
      tester.widget<Text>(find.byKey(const Key('roomLevel'))).data,
      'Lv.2',
    );
    expect(find.byKey(const Key('levelUpCelebration')), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
  testWidgets('升级减少动态效果与飞行中释放', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(
            body: CoinDepositFeedback(
              message: '又长大一点！',
              amount: '+¥27.00',
              level: 5,
              levelUp: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('升级啦！Lv.5'), findsOneWidget);
    expect(find.byKey(const Key('depositCoin')), findsNothing);
    expect(PigCharacter.assetsByLevel.keys, [1, 2, 3, 4, 5]);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoinDepositFeedback(
            key: ValueKey('new'),
            message: '又长大一点！',
            amount: '+¥27.00',
            level: 2,
            levelUp: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
