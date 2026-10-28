import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/memory_repository.dart';
import 'soft_interactions_test.dart' as fixtures;

void main() {
  testWidgets('底栏中央录入、半屏高度、拖高及复位', (tester) async {
    await fixtures.setup(tester, MemoryRepository());
    final add = find.byKey(const Key('newRecord'));
    expect(tester.getCenter(add).dx, closeTo(195, 1));
    await tester.tap(add);
    await tester.pumpAndSettle();
    final panel = find.byKey(const Key('calculatorPanel'));
    expect(tester.getSize(panel).height, closeTo(844 / 2, 2));
    final handle = find.byKey(const Key('calculatorResizeHandle'));
    await tester.drag(handle, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(tester.getSize(panel).height, greaterThan(400));
    await tester.tap(handle);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(tester.getSize(panel).height, closeTo(844 / 2, 2));
  });
  for (final size in [const Size(390, 844), const Size(1219, 813)]) {
    testWidgets('帮助页直接录入并保留页面和心愿归属 $size', (tester) async {
      final c = await fixtures.setup(tester, MemoryRepository(), size: size);
      final goalId = c.goal!.id;
      await tester.tap(find.byKey(const Key('helpTab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('newRecord')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('expression')), '3');
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirmSaving')));
      await tester.pumpAndSettle();
      expect(c.summary.savedMinor, 2300);
      expect(c.goal!.id, goalId);
      expect(c.goalProgressMinor, 2300);
      expect(find.byKey(const Key('helpPage')), findsOneWidget);
    });
  }
  for (final direction in ['nextGoal', 'previousGoal']) {
    testWidgets('卡牌换层和晋升保留图片及进度环状态 $direction', (tester) async {
      final c = await fixtures.setup(tester, MemoryRepository());
      await c.createGoal('相机', 200000, style: 'camera');
      await tester.pumpAndSettle();
      final from = c.goal!.id!;
      final to = c.goals.firstWhere((g) => g.id != from).id!;
      Finder card(int id) => find.byKey(ValueKey('deckCard_$id'));
      Finder image(int id) =>
          find.descendant(of: card(id), matching: find.byType(Image));
      Finder ring(int id) => find.descendant(
        of: card(id),
        matching: find.byType(TweenAnimationBuilder<double>),
      );
      final incomingImage = tester.element(image(to));
      final incomingRing = tester.state(ring(to));
      final outgoingImage = tester.element(image(from));
      await tester.tap(find.byKey(Key(direction)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(identical(tester.element(image(to)), incomingImage), isTrue);
      expect(identical(tester.element(image(from)), outgoingImage), isTrue);
      expect(identical(tester.state(ring(to)), incomingRing), isTrue);
      await tester.pumpAndSettle();
      expect(c.goal!.id, to);
      expect(identical(tester.element(image(to)), incomingImage), isTrue);
      expect(identical(tester.state(ring(to)), incomingRing), isTrue);
      await tester.tap(find.byKey(Key(direction)));
      await tester.pumpAndSettle();
      expect(c.goal!.id, from);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('真实上下拖动换层及写入失败回退保持卡片状态', (tester) async {
    final repo = MemoryRepository();
    final c = await fixtures.setup(tester, repo);
    await c.createGoal('相机', 200000, style: 'camera');
    await tester.pumpAndSettle();
    final original = c.goal!.id;
    final originalImage = tester.element(
      find.descendant(
        of: find.byKey(ValueKey('deckCard_$original')),
        matching: find.byType(Image),
      ),
    );
    await tester.drag(
      find.byKey(const Key('goalCarousel')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    expect(c.goal!.id, isNot(original));
    await tester.drag(
      find.byKey(const Key('goalCarousel')),
      const Offset(0, 90),
    );
    await tester.pumpAndSettle();
    expect(c.goal!.id, original);
    expect(
      identical(
        tester.element(
          find.descendant(
            of: find.byKey(ValueKey('deckCard_$original')),
            matching: find.byType(Image),
          ),
        ),
        originalImage,
      ),
      isTrue,
    );
    repo.fail = true;
    await tester.drag(
      find.byKey(const Key('goalCarousel')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    expect(c.goal!.id, original);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('newRecord'))).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('滑动心愿时中央加号颜色稳定且禁止录入', (tester) async {
    final c = await fixtures.setup(tester, MemoryRepository());
    await c.createGoal('相机', 200000, style: 'camera');
    await tester.pumpAndSettle();
    final add = find.byKey(const Key('newRecord'));
    Color? background() => tester
        .widget<Material>(
          find.descendant(of: add, matching: find.byType(Material)).first,
        )
        .color;
    final before = background();
    final button = tester.widget<IconButton>(add);
    expect(
      button.style!.foregroundColor!.resolve({}),
      button.style!.foregroundColor!.resolve({WidgetState.disabled}),
    );
    final goal = c.goal!.id;
    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('goalCarousel'))),
    );
    await drag.moveBy(const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(background(), before);
    expect(tester.widget<IconButton>(add).onPressed, isNull);
    await tester.tap(add);
    await tester.pump();
    expect(find.byKey(const Key('calculatorPanel')), findsNothing);
    expect(c.goal!.id, goal);
    await drag.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(background(), before);
    await tester.pumpAndSettle();
    expect(background(), before);
    expect(tester.widget<IconButton>(add).onPressed, isNotNull);
    expect(c.goal!.id, isNot(goal));
  });
  testWidgets('帮助按主题展开并展示真实的仓库筹备状态', (tester) async {
    await fixtures.setup(tester, MemoryRepository());
    await tester.tap(find.byKey(const Key('helpTab')));
    await tester.pumpAndSettle();
    final body = find.textContaining('这里记录的是你自行报告');
    expect(body.hitTestable(), findsNothing);
    await tester.tap(find.text('金额的含义'));
    await tester.pumpAndSettle();
    expect(body.hitTestable(), findsOneWidget);
    await tester.ensureVisible(find.text('GitHub · 支持 Wallehog'));
    await tester.tap(find.text('GitHub · 支持 Wallehog'));
    await tester.pumpAndSettle();
    expect(find.textContaining('仓库正在筹备'), findsOneWidget);
  });
}

