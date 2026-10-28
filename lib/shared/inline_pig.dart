import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../app/design_tokens.dart';
import '../domain/pig_room_lines.dart';
import 'pig_character.dart';
import '../character/pig_actor.dart';

class InlinePig extends StatefulWidget {
  const InlinePig({
    super.key,
    required this.level,
    this.feedbackEvent = 0,
    this.imageKey,
    this.depositMotion,
    this.flyawayEvent = 0,
    this.cancelEvent = 0,
  });
  final GlobalKey? imageKey;
  final Animation<double>? depositMotion;
  final int level;
  final int feedbackEvent;
  final int flyawayEvent;
  final int cancelEvent;
  @override
  State<InlinePig> createState() => _InlinePigState();
}

class _InlinePigState extends State<InlinePig> with TickerProviderStateMixin {
  final _lines = PigRoomLines();
  String? _message;
  Timer? _timer;
  late final _bounce = AnimationController(
    vsync: this,
    duration: AppMotion.response,
  );
  late final _flyaway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didUpdateWidget(covariant InlinePig oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cancelEvent != widget.cancelEvent) {
      _flyaway.stop();
      _flyaway.value = 0;
    }
    if (oldWidget.flyawayEvent != widget.flyawayEvent &&
        !MediaQuery.disableAnimationsOf(context)) {
      _flyaway.forward(from: 0);
    }
    if (oldWidget.feedbackEvent != widget.feedbackEvent &&
        !MediaQuery.disableAnimationsOf(context)) {
      _bounce.forward(from: 0);
    }
  }

  void _pat() {
    _flyaway.stop();
    _flyaway.value = 0;
    _timer?.cancel();
    setState(() => _message = _lines.pick(PigRoomLines.pats));
    if (!MediaQuery.disableAnimationsOf(context)) _bounce.forward(from: 0);
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounce.dispose();
    _flyaway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    height: 78,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          label: '小猪，等级 ${widget.level}，摸摸小猪',
          button: true,
          child: GestureDetector(
            key: const Key('pigRoomTab'),
            behavior: HitTestBehavior.opaque,
            onTap: _pat,
            child: SizedBox(
              key: const Key('roomPig'),
              width: 84,
              height: 78,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _bounce,
                      _flyaway,
                      widget.depositMotion,
                    ]),
                    builder: (_, child) {
                      final reduced = MediaQuery.disableAnimationsOf(context);
                      final ms = (widget.depositMotion?.value ?? 0) * 1400;
                      final impact = ((ms - 550) / 160).clamp(0.0, 1.0);
                      final settle = ((ms - 710) / 690).clamp(0.0, 1.0);
                      final squash = ms < 710 ? sin(pi * impact) : 0.0;
                      final jump = sin(pi * settle);
                      return Transform.translate(
                        key: const Key('roomPigBounce'),
                        offset: Offset(
                          0,
                          reduced ? 0 : -5 * sin(pi * _bounce.value) - 7 * jump,
                        ),
                        child: Transform.scale(
                          alignment: Alignment.bottomCenter,
                          scaleX: reduced ? 1 : 1 + .09 * squash,
                          scaleY: reduced ? 1 : 1 - .10 * squash,
                          child: SizedBox(
                            key: widget.imageKey,
                            width: 80,
                            height: 62,
                            child: PigCharacterView(
                              action: _flyaway.isAnimating
                                  ? PigAction.flyaway
                                  : ms > 0 && ms < 1400
                                  ? PigAction.receive
                                  : PigAction.pat,
                              progress: _flyaway.isAnimating
                                  ? _flyaway.value
                                  : ms > 0 && ms < 1400
                                  ? ms / 1400
                                  : _bounce.value,
                              showCoin: _flyaway.isAnimating,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Text(
                    'Lv.${widget.level}',
                    key: const Key('roomLevel'),
                    style: AppType.small.copyWith(fontSize: 10),
                    textScaler: TextScaler.noScaling,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_message != null)
          Positioned(
            right: 86,
            top: 4,
            width: 152,
            child: IgnorePointer(
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF2DFE7)),
                    boxShadow: const [cardShadow],
                  ),
                  child: Text(
                    _message!,
                    key: const Key('pigRoomBubble'),
                    style: AppType.caption.copyWith(color: ink),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
