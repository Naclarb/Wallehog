import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/design_tokens.dart';
import '../../domain/expression_parser.dart';
import '../../domain/wishlist_goal.dart';
import '../../shared/pig_character.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.progressMinor,
    required this.fraction,
    required this.onEdit,
    this.spacious = false,
    this.active = true,
  });
  final bool spacious;
  final bool active;
  final WishlistGoal? goal;
  final int progressMinor;
  final double fraction;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: GoalLayout.minHeight(spacious)),
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: RadialGradient(
        center: Alignment(-.55, -.6),
        radius: 1.8,
        colors: switch (goal?.style) {
          'headphones' => const [
            Color(0xFFFFF6EE),
            Color(0xFFF6DFD6),
            Color(0xFFEFCBBB),
          ],
          'camera' => const [
            Color(0xFFF6F0FF),
            Color(0xFFE9DAF3),
            Color(0xFFD8C4E9),
          ],
          _ => const [Color(0xFFFFF0F6), Color(0xFFF9D4E4), Color(0xFFF4C5D9)],
        },
        stops: const [0, .65, 1],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14BD7896),
          blurRadius: 22,
          offset: Offset(0, 6),
        ),
      ],
    ),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x28FFFFFF), Color(0x00FFFFFF)],
        stops: [0, .45],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .3)),
    ),
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('心愿', style: AppType.caption),
                      Text(
                        goal?.name ?? '给小猪一个期待',
                        style: AppType.heading.copyWith(
                          fontSize: 18,
                          color: goalInk,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: active ? const Key('editGoal') : null,
                  onPressed: onEdit,
                  tooltip: goal == null ? '创建心愿' : '编辑心愿',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .38),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: goalInk,
                  ),
                ),
              ],
            ),
            SizedBox(height: GoalLayout.topGap(spacious)),
            Semantics(
              label: goal == null
                  ? '尚未设置心愿'
                  : '心愿激励进度 ${(fraction * 100).round()}%',
              child: SizedBox(
                width: GoalLayout.ring(spacious),
                height: GoalLayout.ring(spacious),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: goal == null ? 0 : fraction),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.response,
                  curve: AppMotion.curve,
                  builder: (context, value, child) => CustomPaint(
                    painter: _GoalRing(fraction: value),
                    child: child,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 24,
                        child: Container(
                          width: 82,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x205F2644),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (goal == null)
                        const PigCharacter(height: 96)
                      else
                        SizedBox(
                          width: 128,
                          height: 128,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                goalAsset(goal!.style),
                                fit: BoxFit.contain,
                                excludeFromSemantics: true,
                              ),
                              if (active)
                                const IgnorePointer(
                                  child: SizedBox(key: Key('goalItem')),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: GoalLayout.bottomGap(spacious)),
            if (goal != null) ...[
              Text(
                fraction >= 1
                    ? '心愿进度已达成'
                    : '已积累 ${(fraction.clamp(0, 1) * 100).round()}%',
                style: AppType.caption.copyWith(
                  color: goalInk,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '¥${formatMoney(progressMinor)} / ¥${formatMoney(goal!.targetMinor)}',
                  key: active
                      ? const Key('goalProgress')
                      : ValueKey('goalProgress_${goal?.id}'),
                  style: AppType.goalAmount,
                ),
              ),
            ] else
              IconButton(
                key: const Key('createGoal'),
                tooltip: '设置心愿',
                onPressed: onEdit,
                icon: const Icon(Icons.add_rounded, color: deepPink),
              ),
          ],
        ),
        if (active)
          const Positioned.fill(
            child: IgnorePointer(child: SizedBox(key: Key('goalCard'))),
          ),
      ],
    ),
  );
}

class _GoalRing extends CustomPainter {
  const _GoalRing({required this.fraction});
  final double fraction;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = rect.deflate(6);
    final track = Paint()
      ..color = const Color(0x50FFFFFF)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawArc(circle, -math.pi / 2, math.pi * 2, false, track);
    if (fraction > 0) {
      canvas.drawArc(
        circle.shift(const Offset(0, 2)),
        -math.pi / 2,
        math.pi * 2 * fraction.clamp(0, 1),
        false,
        Paint()
          ..color = const Color(0x16B45983)
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      final progress = Paint()
        ..color = Colors.white
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        circle,
        -math.pi / 2,
        math.pi * 2 * fraction.clamp(0, 1),
        false,
        progress,
      );
    }
  }

  @override
  bool shouldRepaint(_GoalRing old) => old.fraction != fraction;
}
