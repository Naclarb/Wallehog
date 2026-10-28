import 'package:flutter/material.dart';
import '../character/pig_actor.dart';

/// 角色展示接口：只接受动作和进度，不读取业务或存储。
class PigCharacter extends StatelessWidget {
  const PigCharacter({super.key, this.height = 180, this.level = 1});
  final double height;
  final int level;
  // 兼容已有等级展示，所有等级均使用同一角色。
  static const asset = 'soft-pig-v1';
  static const assetsByLevel = {
    1: asset,
    2: asset,
    3: asset,
    4: asset,
    5: asset,
  };
  static const canvasSize = Size(400, 420);
  static const slot = Offset(200 / 400, 143 / 420);

  @override
  Widget build(BuildContext context) => Semantics(
    label: '陪伴你的小猪',
    image: true,
    child: SizedBox(
      height: height,
      width: height * 1.4,
      child: const PigCharacterView(),
    ),
  );
}

/// 渲染器只消费展示状态；业务层可不依赖具体画法。
class PigCharacterView extends StatelessWidget {
  const PigCharacterView({
    super.key,
    this.action = PigAction.rest,
    this.progress = 0,
    this.showCoin = true,
  });
  final PigAction action;
  final double progress;
  final bool showCoin;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: PigPainter(
      action: action,
      time: progress.clamp(0.0, 1.0),
      reduced: MediaQuery.disableAnimationsOf(context),
      showCoin: showCoin,
    ),
  );
}
