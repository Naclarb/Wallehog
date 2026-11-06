import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../domain/wishlist_goal.dart';

class WishBindingButton extends StatelessWidget {
  const WishBindingButton({
    super.key,
    required this.goals,
    required this.goalId,
    required this.onPressed,
  });

  final List<WishlistGoal> goals;
  final int? goalId;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final goal = goals.where((goal) => goal.id == goalId).firstOrNull;
    return Semantics(
      label: '绑定心愿，${goal?.name ?? '未绑定'}',
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Tooltip(
          message: '绑定心愿',
          child: Material(
            color: softPink,
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: InkWell(
              key: const Key('wishBinding'),
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 22, color: mutedInk),
                    const Spacer(),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: _WishImage(goal: goal),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more_rounded, color: mutedInk),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns 0 for unbound and null for cancellation. Selection never writes data.
Future<int?> showWishBindingPicker(
  BuildContext context, {
  required List<WishlistGoal> goals,
  required int? selectedId,
}) => showDialog<int>(
  context: context,
  builder: (context) => Dialog(
    key: const Key('wishBindingPicker'),
    backgroundColor: pageBackground,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 360,
        maxHeight: MediaQuery.sizeOf(context).height * .7,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.link_rounded, color: deepPink),
                const Spacer(),
                IconButton(
                  tooltip: '取消',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: mutedInk),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, area) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final goal in <WishlistGoal?>[null, ...goals])
                    SizedBox(
                      width: (area.maxWidth - 24) / 4,
                      height: 72,
                      child: Tooltip(
                        message: goal?.name ?? '未绑定',
                        child: Semantics(
                          label: goal?.name ?? '未绑定',
                          selected: selectedId == goal?.id,
                          button: true,
                          child: Material(
                            color: selectedId == goal?.id
                                ? const Color(0xFFF2DFE6)
                                : const Color(0xFFF9F1F0),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              key: Key('bindingOption_${goal?.id ?? 0}'),
                              onTap: () =>
                                  Navigator.pop(context, goal?.id ?? 0),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: _WishImage(goal: goal),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

class _WishImage extends StatelessWidget {
  const _WishImage({required this.goal});
  final WishlistGoal? goal;

  @override
  Widget build(BuildContext context) => goal == null
      ? const Icon(Icons.block_rounded, size: 24, color: mutedInk)
      : Image.asset(
          goalAsset(goal!.style),
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        );
}
