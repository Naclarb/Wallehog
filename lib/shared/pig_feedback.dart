import 'dart:async';
import 'package:flutter/material.dart';
import 'pig_character.dart';
import '../app/design_tokens.dart';

/// 仅消费一次 UI 成功事件；不会写入数据库或修改成长计数。
class PigFeedback extends StatefulWidget {
  const PigFeedback({super.key, required this.event, this.height = 180});
  final int event;
  final double height;
  @override
  State<PigFeedback> createState() => _PigFeedbackState();
}

class _PigFeedbackState extends State<PigFeedback> {
  Timer? _timer;
  bool _happy = false;
  @override
  void didUpdateWidget(PigFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event != widget.event) {
      _timer?.cancel();
      _happy = true;
      _timer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _happy = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnimatedScale(
        scale: _happy && !MediaQuery.disableAnimationsOf(context) ? 1.05 : 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        child: PigCharacter(height: widget.height),
      ),
      const SizedBox(height: 2),
      Text(_happy ? '又一个小确幸，小猪收到啦 ♡' : '把小确幸，慢慢变成大期待', style: AppType.caption),
    ],
  );
}
