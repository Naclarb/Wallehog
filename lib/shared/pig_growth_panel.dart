import 'package:flutter/material.dart';
import '../application/records_controller.dart';
import '../domain/pig_growth.dart';
import '../domain/pig_bond.dart';
import '../app/design_tokens.dart';
import 'pig_character.dart';

class PigGrowthPanel extends StatelessWidget {
  const PigGrowthPanel({super.key, required this.controller});
  final RecordsController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final growth = PigGrowth(controller.summary.goodChoices);
      return Column(
        children: [
          PigCharacter(height: 90, level: growth.level),
          Text(
            'Lv.${growth.level}',
            key: const Key('pigGrowthLevel'),
            style: AppType.heading,
          ),
          const SizedBox(height: 8),
          Text(pigBond(growth.choices), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            '已经做了 ${growth.choices} 次好选择',
            style: const TextStyle(color: mutedInk),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: growth.fraction,
            semanticsLabel: '小猪成长进度',
          ),
          const SizedBox(height: 8),
          Text(
            growth.nextThreshold == null
                ? 'Lv.5 已满级，继续收藏你的小确幸'
                : '再有 ${growth.remaining} 次好选择，遇见 Lv.${growth.level + 1}',
            key: const Key('pigGrowthProgress'),
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  );
}
