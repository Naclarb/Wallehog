import '../app/app_strings.dart';
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
          Text(
            tr(context, pigBond(growth.choices)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            tr(context, '已经做了 {0} 次好选择', [growth.choices]),
            style: const TextStyle(color: mutedInk),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: growth.fraction,
            semanticsLabel: tr(context, '小猪成长进度'),
          ),
          const SizedBox(height: 8),
          Text(
            growth.nextThreshold == null
                ? tr(context, 'Lv.5 已满级，继续收藏你的小确幸')
                : tr(context, '再有 {0} 次好选择，遇见 Lv.{1}', [
                    growth.remaining,
                    growth.level + 1,
                  ]),
            key: const Key('pigGrowthProgress'),
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  );
}
