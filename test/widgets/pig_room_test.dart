import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/app/wallehog_app.dart';
import 'package:wallehog/application/records_controller.dart';
import 'package:wallehog/domain/pig_room_lines.dart';
import 'package:wallehog/features/entry/calculator_sheet.dart';
import '../support/memory_repository.dart';
import '../data/pig_growth_repository_test.dart' show quick;

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(360, 800),
    const Size(390, 844),
    const Size(813, 1219),
    const Size(1219, 813),
  ]) {
    testWidgets('小猪屋 $size 本地互动、成长刷新与首页加号', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = MemoryRepository();
      final c = RecordsController(repo);
      addTearDown(c.dispose);
      await c.load();
      await tester.pumpWidget(WallehogApp(controller: c));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pigRoomTab')));
      await tester.pumpAndSettle();
      expect(find.text('Lv.1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('roomPig')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(
        tester
            .widget<Transform>(find.byKey(const Key('roomPigBounce')))
            .transform
            .storage[13],
        lessThan(0),
      );
      expect(
        PigRoomLines.pats,
        contains(
          tester.widget<Text>(find.byKey(const Key('pigRoomBubble'))).data,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('patPig')), findsNothing);
      expect(find.byKey(const Key('talkPig')), findsNothing);
      expect(c.records, isEmpty);
      expect(c.summary.savedMinor, 0);
      for (var i = 0; i < 5; i++) {
        await c.save(quick(1));
      }
      await tester.pumpAndSettle();
      expect(find.text('Lv.2'), findsOneWidget);
      await c.save(quick(999999999, previous: c.records.first));
      await tester.pumpAndSettle();
      expect(find.text('Lv.2'), findsOneWidget);
      await c.delete(c.records.first.id!);
      await tester.pumpAndSettle();
      expect(find.text('Lv.1'), findsOneWidget);
      expect(find.byKey(const Key('newRecord')).hitTestable(), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      for (final tab in ['helpTab', 'homeTab']) {
        await tester.tap(find.byKey(Key(tab)));
        await tester.pumpAndSettle();
        if (tab == 'helpTab') {
          expect(find.byKey(const Key('helpPage')), findsOneWidget);
          expect(
            find.byKey(const Key('newRecord')).hitTestable(),
            findsOneWidget,
          );
        }
      }
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      expect(find.byType(CalculatorSheet), findsOneWidget);
      Navigator.of(tester.element(find.byType(CalculatorSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pigRoomTab')));
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      final reopened = RecordsController(repo);
      addTearDown(reopened.dispose);
      await reopened.load();
      await tester.pumpWidget(WallehogApp(controller: reopened));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pigRoomTab')));
      await tester.pumpAndSettle();
      expect(find.text('Lv.1'), findsOneWidget);
      expect(reopened.summary.goodChoices, 4);
    });
  }
}
