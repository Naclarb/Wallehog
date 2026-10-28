import 'package:flutter/material.dart';

// Phase 2：390 × 844 为手机构图基准；金额与进度只在展示层使用这些样式。
const pageBackground = Color(0xFFFFF9F8);
const primaryPink = Color(0xFFE77EA5);
const deepPink = Color(0xFFAC416D);
const ink = Color(0xFF302832);
const mutedInk = Color(0xFF8D7B85);
const positiveGreen = Color(0xFF27865B);
Color moneyColor(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'zh'
    ? const Color(0xFFB83F4E)
    : positiveGreen;

const softPink = Color(0xFFFFEBF1);

const goalGradient = [Color(0xFFF9CFE1), Color(0xFFFCE9F2)];
const goalInk = Color(0xFF583044);
const goalMutedInk = Color(0xFF82435F);

abstract final class AppSize {
  static const double contentMax = 430,
      hero = 200,
      heroCompact = 154,
      goalRing = 165,
      primaryAction = 68,
      touchTarget = 48;
}

abstract final class AppSpace {
  static const double xs = 4,
      sm = 8,
      md = 12,
      lg = 16,
      xl = 24,
      xxl = 32,
      page = 20;
}

abstract final class AppRadius {
  static const double card = 28, control = 18, sheet = 28;
}

abstract final class AppType {
  static const goalAmount = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: goalInk,
  );
  static const savedAmount = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1.2,
    color: ink,
  );
  static const recordAmount = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: positiveGreen,
  );
  static const brand = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -.9,
    color: ink,
  );
  static const heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: ink,
  );
  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: ink,
  );
  static const body = TextStyle(fontSize: 14, height: 1.45, color: ink);
  static const caption = TextStyle(fontSize: 12, height: 1.45, color: mutedInk);
  static const small = TextStyle(fontSize: 12, height: 1.35, color: mutedInk);
  static const money = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1.12,
    letterSpacing: -1.8,
    color: ink,
  );
}

abstract final class AppMotion {
  static const response = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;
}

abstract final class GoalLayout {
  static double minHeight(bool spacious) => spacious ? 400 : 276;
  static double ring(bool spacious) => spacious ? 240 : 184;
  static double topGap(bool spacious) => spacious ? 14 : 0;
  static double bottomGap(bool spacious) => spacious ? 12 : 2;
}

const cardShadow = BoxShadow(
  color: Color(0x0CE0A5BC),
  blurRadius: 22,
  offset: Offset(0, 8),
);
const actionShadow = BoxShadow(
  color: Color(0x40D96391),
  blurRadius: 20,
  offset: Offset(0, 7),
);
BoxDecoration softCard({Color color = Colors.white}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(AppRadius.card),
  border: Border.all(color: const Color(0xFFF5E8E9)),
  boxShadow: const [cardShadow],
);
