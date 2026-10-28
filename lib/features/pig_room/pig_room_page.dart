import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/design_tokens.dart';
import '../../application/records_controller.dart';
import '../../domain/pig_growth.dart';
import '../../domain/pig_room_lines.dart';
import '../../shared/pig_character.dart';

class PigRoomPage extends StatefulWidget {
  const PigRoomPage({super.key, required this.controller});
  final RecordsController controller;

  @override
  State<PigRoomPage> createState() => _PigRoomPageState();
}

class _PigRoomPageState extends State<PigRoomPage>
    with SingleTickerProviderStateMixin {
  final _lines = PigRoomLines();
  late String _message = _lines.pick(PigRoomLines.talks);
  late final _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  void _pat() {
    setState(() => _message = _lines.pick(PigRoomLines.pats));
    if (!MediaQuery.disableAnimationsOf(context)) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final growth = PigGrowth(widget.controller.summary.goodChoices);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              key: const Key('pigRoomScroll'),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('小猪的角落', style: AppType.heading),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment(0, -.2),
                        radius: 1,
                        colors: [Color(0xFFFFF5F9), Color(0xFFF8D8E7)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(22),
                                bottomRight: Radius.circular(22),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                            child: Text(
                              _message,
                              key: const Key('pigRoomBubble'),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, area) => Semantics(
                            button: true,
                            label: '摸摸小猪',
                            child: GestureDetector(
                              key: const Key('roomPig'),
                              behavior: HitTestBehavior.opaque,
                              onTap: _pat,
                              child: AnimatedBuilder(
                                animation: _bounce,
                                builder: (context, child) =>
                                    Transform.translate(
                                      key: const Key('roomPigBounce'),
                                      offset: Offset(
                                        0,
                                        MediaQuery.disableAnimationsOf(context)
                                            ? 0
                                            : -10 * sin(pi * _bounce.value),
                                      ),
                                      child: child,
                                    ),
                                child: PigCharacter(
                                  height: min(220, area.maxWidth / 1.4),
                                  level: growth.level,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!widget.controller.loaded) ...[
                          Text(widget.controller.error ?? '正在读取成长状态…'),
                          TextButton(
                            onPressed: widget.controller.busy
                                ? null
                                : widget.controller.load,
                            child: const Text('重新读取'),
                          ),
                        ] else ...[
                          Text(
                            'Lv.${growth.level}',
                            key: const Key('roomLevel'),
                            style: AppType.heading,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
