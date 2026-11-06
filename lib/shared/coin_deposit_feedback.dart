import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pig_character.dart';
import '../domain/deposit_moment.dart';

/// 仅展示已提交的保存结果，不保存或累计业务数据。
class CoinDepositFeedback extends StatefulWidget {
  const CoinDepositFeedback({
    super.key,
    required this.message,
    required this.amount,
    this.level = 1,
    this.levelUp = false,
    this.moment = DepositMoment.normal,
    this.reaction = 0,
    this.targetKey,
    this.motion,
  });
  final String message;
  final String amount;
  final int level;
  final bool levelUp;
  final DepositMoment moment;
  final int reaction;
  final GlobalKey? targetKey;
  final Animation<double>? motion;
  @override
  State<CoinDepositFeedback> createState() => _CoinDepositFeedbackState();
}

class _CoinDepositFeedbackState extends State<CoinDepositFeedback>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool? _reduced;
  final _canvas = GlobalKey();
  Animation<double> get motion => widget.motion ?? _motion;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced == reduced) return;
    _reduced = reduced;
    if (reduced) {
      _motion.value = 1;
    } else if (widget.motion == null) {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  // 投币口使用角色逻辑画布坐标，先计算 contain 后的绘制矩形，
  // 再通过真实 RenderBox 转到反馈层坐标；滚动、SafeArea、侧栏均自然计入。
  Offset? _slot() {
    final target = widget.targetKey?.currentContext?.findRenderObject();
    final canvas = _canvas.currentContext?.findRenderObject();
    if (target is! RenderBox || canvas is! RenderBox || !target.attached) {
      return null;
    }
    final rect = applyBoxFit(
      BoxFit.contain,
      PigCharacter.canvasSize,
      target.size,
    ).destination;
    final inset = Offset(
      (target.size.width - rect.width) / 2,
      (target.size.height - rect.height) / 2,
    );
    return canvas.globalToLocal(
      target.localToGlobal(
        inset +
            Offset(
              rect.width * PigCharacter.slot.dx,
              rect.height * PigCharacter.slot.dy,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Semantics(
      liveRegion: true,
      label: '已记录 ${widget.amount}，${widget.message}',
      child: ExcludeSemantics(
        child: SizedBox.expand(
          key: _canvas,
          child: AnimatedBuilder(
            animation: motion,
            builder: (context, _) {
              final reduced = MediaQuery.disableAnimationsOf(context);
              final celebration =
                  widget.levelUp || widget.moment == DepositMoment.completed;
              final ms = motion.value * 1400;
              final t = (ms / 550).clamp(0.0, 1.0);
              final size = MediaQuery.sizeOf(context);
              final end =
                  _slot() ??
                  (widget.targetKey == null
                      ? Offset(size.width * .8, 70)
                      : null);
              final start = Offset(
                math.max(30, (end?.dx ?? size.width) - 120),
                (end?.dy ?? 70) + 140,
              );
              final u = Curves.easeInOutCubic.transform(t);
              final position = end == null
                  ? start
                  : Offset.lerp(start, end, u)! +
                        Offset(
                          -36 * math.sin(math.pi * u),
                          -64 * math.sin(math.pi * u),
                        );
              final shrink = t < .72
                  ? 1.0
                  : (1 - (t - .72) / .28).clamp(0.0, 1.0);
              return Stack(
                key: const Key('depositFeedback'),
                children: [
                  if (!celebration && !reduced && t < 1 && end != null)
                    Positioned(
                      left: position.dx - 14,
                      top: position.dy - 14,
                      child: Transform.scale(
                        scale: shrink,
                        child: Transform.rotate(
                          angle: t * math.pi * .7,
                          child: Container(
                            key: const Key('depositCoin'),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFED9D),
                                  Color(0xFFF4B53F),
                                  Color(0xFFD78D22),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFFFFE7A0),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x30A96C21),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '¥',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFAC741F),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (celebration && !reduced && end != null)
                    Positioned(
                      left: end.dx - 48,
                      top: end.dy - 65,
                      child: Transform.scale(
                        scale: Curves.elasticOut.transform(
                          (ms / 700).clamp(0.0, 1.0),
                        ),
                        child: const Text(
                          '✨ 🎉 ✨',
                          key: Key('celebrationAnimation'),
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Opacity(
                          opacity: reduced
                              ? 1
                              : ((ms - 550) / 180).clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '已记录 ${widget.amount}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.moment.label != null)
                                  Text(
                                    widget.moment.label!,
                                    key: const Key('depositMoment'),
                                  ),
                                if (widget.levelUp)
                                  Text(
                                    '升级啦！Lv.${widget.level}',
                                    key: const Key('levelUpCelebration'),
                                  ),
                                Text(
                                  'Lv.${widget.level}',
                                  key: const Key('rewardGrowthLevel'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8D7B85),
                                  ),
                                ),
                                Opacity(
                                  opacity: reduced
                                      ? 1
                                      : ((ms - 550) / 180).clamp(0.0, 1.0),
                                  child: Text(widget.message),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
