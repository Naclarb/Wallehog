import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/wishlist_goal.dart';
import '../../app/design_tokens.dart';
import '../../application/records_controller.dart';
import '../wishlist/goal_editor.dart';
import 'goal_card.dart';

class GoalCarousel extends StatefulWidget {
  const GoalCarousel({
    super.key,
    required this.controller,
    this.spacious = false,
    this.onTransitionChanged,
  });
  final RecordsController controller;
  final bool spacious;
  final ValueChanged<bool>? onTransitionChanged;
  @override
  State<GoalCarousel> createState() => _GoalCarouselState();
}

class _GoalCarouselState extends State<GoalCarousel>
    with SingleTickerProviderStateMixin {
  bool _selecting = false;
  double _drag = 0;
  double _height = 300;
  int _direction = 1;
  WishlistGoal? _from;
  WishlistGoal? _to;
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 540),
  );
  int get _selected => math.max(
    0,
    widget.controller.goals.indexWhere(
      (g) => g.id == widget.controller.goal?.id,
    ),
  );

  void _prepare(int delta) {
    final c = widget.controller;
    if (_from == null) widget.onTransitionChanged?.call(true);
    _from = c.goal;
    _direction = delta;
    _to = c.goals[(_selected + delta) % c.goals.length];
  }

  Future<void> _finish({required bool commit}) async {
    if (_selecting || _from == null) return;
    _selecting = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    try {
      if (commit) {
        if (!reduced) {
          await _turn.animateTo(1, curve: Curves.easeInOutCubic).orCancel;
        }
        if (!mounted) return;
        final success = await widget.controller.selectGoal(_to!.id!);
        if (!mounted) return;
        if (!success && !reduced) {
          await _turn
              .animateBack(
                0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
              )
              .orCancel;
        }
      } else if (!reduced) {
        await _turn
            .animateBack(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      }
    } on TickerCanceled {
      // 页面退出时动画取消，尚未提交的选择不写入。
    } finally {
      if (mounted) {
        setState(() {
          _from = null;
          _to = null;
          _drag = 0;
          _selecting = false;
          _turn.reset();
        });
        widget.onTransitionChanged?.call(false);
      }
    }
  }

  void _move(int delta) {
    if (_selecting ||
        !widget.controller.canWrite ||
        widget.controller.goals.length < 2) {
      return;
    }
    _prepare(delta);
    setState(() {});
    _finish(commit: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 反向切换可能首次展示未在预览中的心愿，提前解码内置物件。
    for (final style in ['gift', 'ps5', 'headphones', 'camera']) {
      precacheImage(AssetImage(goalAsset(style)), context);
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    if (_from != null) {
      final notify = widget.onTransitionChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) => notify?.call(false));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    void edit() => showGoalEditor(context, c);
    if (c.goals.isEmpty) {
      return GoalCard(
        goal: null,
        progressMinor: 0,
        fraction: 0,
        spacious: widget.spacious,
        onEdit: c.canWrite ? edit : null,
      );
    }
    return LayoutBuilder(
      builder: (context, area) {
        final scaler = MediaQuery.textScalerOf(context);
        double height(String text, TextStyle style, double width) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout(maxWidth: math.max(30, width));
          final value = painter.height;
          painter.dispose();
          return value;
        }

        final width = area.maxWidth - 16;
        final captionHeight = height('已积累 100%', AppType.caption, width - 36);
        final titleHeight = c.goals
            .map(
              (g) => height(
                g.name,
                AppType.heading.copyWith(fontSize: 18),
                width - 36 - 48,
              ),
            )
            .reduce(math.max);
        final header = math.max(
          48,
          titleHeight + height('心愿', AppType.caption, width - 36 - 48),
        );
        final cardHeight = math.max(
          GoalLayout.minHeight(widget.spacious),
          8 +
              header +
              GoalLayout.topGap(widget.spacious) +
              GoalLayout.ring(widget.spacious) +
              GoalLayout.bottomGap(widget.spacious) +
              captionHeight +
              2 +
              scaler.scale(16) * 1.3 +
              10 +
              4,
        );
        _height = cardHeight;
        final front = _from ?? c.goal!;
        final next =
            _to ??
            (c.goals.length > 1
                ? c.goals[(_selected + 1) % c.goals.length]
                : null);
        Widget card(WishlistGoal goal, bool active) => GoalCard(
          key: ValueKey('deckCard_${goal.id}'),
          goal: goal,
          active: active,
          progressMinor: goal.progressMinor(c.records),
          fraction: goal.progressFraction(c.records),
          spacious: widget.spacious,
          onEdit: active && !_selecting && _from == null && c.canWrite
              ? edit
              : null,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: cardHeight + 16,
              child: GestureDetector(
                key: const Key('goalCarousel'),
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: !c.canWrite || _selecting || next == null
                    ? null
                    : (d) {
                        _drag = (_drag + d.delta.dy).clamp(
                          -_height * .65,
                          _height * .65,
                        );
                        _prepare(_drag >= 0 ? 1 : -1);
                        _turn.value = (_drag.abs() / (_height * 1.3)).clamp(
                          0,
                          .48,
                        );
                        setState(() {});
                      },
                onVerticalDragEnd: (d) {
                  if (_from == null || _selecting) return;
                  _finish(
                    commit:
                        _drag.abs() > 35 ||
                        d.velocity.pixelsPerSecond.dy.abs() > 350,
                  );
                },
                onVerticalDragCancel: () => _finish(commit: false),
                child: AnimatedBuilder(
                  animation: _turn,
                  builder: (context, _) {
                    final t = MediaQuery.disableAnimationsOf(context)
                        ? 0.0
                        : _turn.value;
                    final outbound = (t / .55).clamp(0.0, 1.0);
                    final returning = ((t - .55) / .45).clamp(0.0, 1.0);
                    final travel = t <= .55
                        ? outbound
                        : 1 - Curves.easeOutCubic.transform(returning);
                    final lift = Curves.easeOutCubic.transform(t);
                    // 同一心愿始终使用相同的包装结构；换层只改变绘制顺序和变换。
                    // 预览晋升为顶牌时保留 Image / TweenAnimationBuilder 的 Element。
                    Widget layer(WishlistGoal goal, bool outgoing) {
                      final active = _from == null
                          ? goal.id == c.goal?.id
                          : (t < .55 ? outgoing : !outgoing);
                      return Positioned(
                        key: ValueKey('deckLayer_${goal.id}'),
                        left: 0,
                        right: 0,
                        top: outgoing ? 12 * returning : 12 * (1 - lift),
                        height: cardHeight,
                        child: ExcludeSemantics(
                          excluding: !active,
                          child: IgnorePointer(
                            ignoring: !active || _from != null,
                            child: Transform.translate(
                              key: ValueKey('deckTranslation_${goal.id}'),
                              offset: outgoing
                                  ? Offset(
                                      travel * 12 * _direction,
                                      travel * (cardHeight + 24) * _direction,
                                    )
                                  : Offset.zero,
                              child: Transform.rotate(
                                angle: outgoing
                                    ? travel * .045 * _direction
                                    : 0,
                                child: Transform.scale(
                                  scale: outgoing
                                      ? 1 - .055 * outbound
                                      : .945 + .055 * lift,
                                  child: RepaintBoundary(
                                    child: card(goal, active),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final frontLayer = layer(front, true);
                    final nextLayer = next == null ? null : layer(next, false);
                    return ClipRect(
                      child: Stack(
                        key: const Key('goalDeckLayers'),
                        children: [
                          if (nextLayer != null && t < .55) nextLayer,
                          frontLayer,
                          if (nextLayer != null && t >= .55) nextLayer,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      '${_selected + 1} / ${c.goals.length}',
                      style: AppType.caption,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('previousGoal'),
                  visualDensity: VisualDensity.compact,
                  tooltip: '上一个心愿',
                  onPressed:
                      !c.canWrite ||
                          _selecting ||
                          _from != null ||
                          c.goals.length < 2
                      ? null
                      : () => _move(-1),
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
                ),
                IconButton(
                  key: const Key('nextGoal'),
                  visualDensity: VisualDensity.compact,
                  tooltip: '下一个心愿',
                  onPressed:
                      !c.canWrite ||
                          _selecting ||
                          _from != null ||
                          c.goals.length < 2
                      ? null
                      : () => _move(1),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ),
                IconButton(
                  key: const Key('addGoal'),
                  visualDensity: VisualDensity.compact,
                  tooltip: '添加心愿',
                  onPressed: !c.canWrite || _selecting || _from != null
                      ? null
                      : () => showGoalEditor(context, c, creating: true),
                  icon: const Icon(Icons.add_rounded, color: deepPink),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
