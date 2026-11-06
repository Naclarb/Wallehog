import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallehog/shared/inline_pig.dart';
import 'package:wallehog/shared/pig_character.dart';

void main() {
  testWidgets('Home pig has no level label and still responds to taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InlinePig(level: 1))),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('roomPig')), findsOneWidget);
    expect(find.text('Lv.1'), findsNothing);
    expect(find.byKey(const Key('roomLevel')), findsNothing);
    final pigBounds = tester.getRect(find.byType(PigCharacterView));
    expect(tester.getSize(find.byType(InlinePig)).height, pigBounds.height);
    expect(
      tester.getRect(find.byKey(const Key('roomPig'))).bottom,
      pigBounds.bottom,
    );
    await tester.tap(find.byKey(const Key('pigRoomTab')));
    await tester.pump();
    expect(find.byKey(const Key('pigRoomBubble')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
