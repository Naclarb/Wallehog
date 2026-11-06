import 'package:flutter/material.dart';
import '../../app/design_tokens.dart';

/// 与手机共用入口语义，按窗口宽度切换，不依赖设备型号。
class TabletNavigation extends StatelessWidget {
  const TabletNavigation({
    super.key,
    required this.selectedIndex,
    required this.onHome,
    required this.onHelp,
    required this.primaryAction,
  });
  final Widget primaryAction;
  final int selectedIndex;
  final VoidCallback onHome;
  final VoidCallback onHelp;
  @override
  Widget build(BuildContext context) => Container(
    color: ink,
    child: SafeArea(
      right: false,
      child: SingleChildScrollView(
        child: IntrinsicHeight(
          child: NavigationRail(
            key: const Key('tabletNavigation'),
            backgroundColor: ink,
            minWidth: 88,
            selectedIndex: selectedIndex == 1 ? 2 : 0,
            groupAlignment: -1,
            labelType: NavigationRailLabelType.none,
            selectedIconTheme: const IconThemeData(color: ink, size: 24),
            unselectedIconTheme: const IconThemeData(
              color: Colors.white,
              size: 24,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: primaryPink,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            indicatorColor: primaryPink,
            onDestinationSelected: (index) {
              if (index == 0) onHome();
              if (index == 2) onHelp();
            },
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined, key: Key('homeTab')),
                label: Text('首页'),
              ),
              NavigationRailDestination(
                icon: primaryAction,
                label: const Text('记录节省'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.help_outline_rounded, key: Key('helpTab')),
                label: Text('帮助'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
