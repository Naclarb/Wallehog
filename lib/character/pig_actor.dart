import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PigAction {
  rest('安静待机', 1000, '放松站好，等待下一次相遇'),
  receive('认真接币', 1400, '注意 → 迎接 → 入槽 → 满足'),
  first('第一次惊喜', 1600, '睁大眼睛，双手靠近胸口'),
  halfway('过半点头', 1500, '抬头，认真点一下头'),
  complete('达成欢呼', 1900, '蓄力，小跳一次，张手庆祝'),
  pat('轻触回应', 1100, '侧倾，眯眼，折耳慢半拍'),
  hug('抱住金币', 1500, '把金币收近，珍惜地抱好'),
  flyaway('金币溜走啦', 3000, '长翅膀 → 伸手扑空 → 屁股墩 → 自己站好');

  const PigAction(this.label, this.milliseconds, this.description);
  final String label;
  final int milliseconds;
  final String description;
}

double window(double t, double a, double b) =>
    t <= a || t >= b ? 0 : math.sin(math.pi * (t - a) / (b - a));

double ramp(double t, double a, double b) {
  final u = ((t - a) / (b - a)).clamp(0.0, 1.0);
  return u * u * (3 - 2 * u);
}

/// Display-only pose. No database or business event API.
class PigPose {
  const PigPose({
    this.jump = 0,
    this.squash = 0,
    this.tilt = 0,
    this.ear = 0,
    this.arm = 0,
    this.eye = 1,
    this.look = 0,
    this.smile = 0,
    this.hug = 0,
    this.shift = 0,
    this.drop = 0,
    this.lookX = 0,
  });
  final double jump,
      squash,
      tilt,
      ear,
      arm,
      eye,
      look,
      smile,
      hug,
      shift,
      drop,
      lookX;
  factory PigPose.sample(PigAction action, double time) {
    final t = time.clamp(0.0, 1.0);
    final beat = window(t, .15, .9);
    switch (action) {
      case PigAction.rest:
        return const PigPose();
      case PigAction.receive:
        return PigPose(
          look: -window(t, .02, .42) * 7,
          arm: window(t, .08, .64) * .5,
          squash: window(t, .39, .53) * .09 - window(t, .53, .76) * .035,
          jump: window(t, .53, .83) * 10,
          ear: window(t, .46, .86) * .22,
          eye: 1 - window(t, .56, .82) * .84,
          smile: window(t, .43, .98),
        );
      case PigAction.first:
        return PigPose(
          eye: 1 + window(t, .08, .43) * .24,
          arm: beat * .8,
          jump: window(t, .4, .8) * 7,
          smile: beat,
          ear: window(t, .26, .91) * -.18,
        );
      case PigAction.halfway:
        return PigPose(
          look: -window(t, .05, .35) * 5,
          squash: window(t, .35, .64) * .055,
          eye: 1 - window(t, .37, .69) * .85,
          arm: beat * .3,
          smile: beat,
          ear: window(t, .44, .85) * .12,
        );
      case PigAction.complete:
        return PigPose(
          squash: window(t, .05, .27) * .11 - window(t, .28, .48) * .04,
          jump: window(t, .27, .64) * 35,
          arm: window(t, .18, .85) * 1.7,
          eye: 1 - window(t, .33, .8) * .9,
          ear: window(t, .36, .79) * -.3,
          smile: beat,
        );
      case PigAction.pat:
        return PigPose(
          tilt: beat * -.09,
          eye: 1 - window(t, .16, .83) * .91,
          ear: window(t, .27, .96) * .3,
          smile: beat,
          arm: beat * .2,
        );
      case PigAction.hug:
        return PigPose(
          hug: beat,
          arm: beat * .65,
          eye: 1 - window(t, .4, .86) * .85,
          smile: beat,
          tilt: beat * .035,
        );
      case PigAction.flyaway:
        final fall = ramp(t, .46, .62) * (1 - ramp(t, .79, .98));
        return PigPose(
          look: -window(t, .06, .47) * 10,
          lookX: window(t, .17, .66) * 7,
          shift: window(t, .25, .98) * 10 - fall * 20,
          drop: -fall * 55,
          tilt: fall * .88 + window(t, .28, .46) * .13,
          arm: window(t, .2, .62) * 1.5 + window(t, .66, .9) * .3,
          squash: window(t, .59, .73) * .1,
          eye: 1 + window(t, .16, .48) * .2 - window(t, .6, .76) * .92,
          ear: window(t, .48, .8) * .4,
          smile: window(t, .8, .99) * .7,
        );
    }
  }
}

/// Editable 2D vector artwork. Canvas 400×420; ground y=364; slot=(200,143).
class PigPainter extends CustomPainter {
  const PigPainter({
    this.action = PigAction.rest,
    this.time = 0,
    this.guides = false,
    this.reduced = false,
    this.showCoin = true,
  });
  final PigAction action;
  final double time;
  final bool guides, reduced;
  final bool showCoin;
  static const pink = Color(0xFFF6A7BA),
      deep = Color(0xFFE889A3),
      ink = Color(0xFF51333D),
      blush = Color(0xFFF07F9C);
  @override
  void paint(Canvas c, Size size) {
    final scale = math.min(size.width / 400, size.height / 420);
    c.save();
    c.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 420 * scale) / 2,
    );
    c.scale(scale);
    c.clipRect(const Rect.fromLTWH(0, 0, 400, 420));
    final p = reduced ? const PigPose() : PigPose.sample(action, time);
    oval(
      c,
      Rect.fromCenter(
        center: Offset(200 + p.shift, 369),
        width: 205 - p.jump * 1.1,
        height: 15 - p.jump * .12,
      ),
      const Color(0xFFE3D6CC),
    );
    c.save();
    c.translate(200 + p.shift, 358 - p.jump + p.drop);
    c.rotate(p.tilt);
    c.scale(1 + p.squash, 1 - p.squash);
    c.translate(-200, -358);
    round(c, const Rect.fromLTWH(122, 320, 53, 44), 19, deep);
    round(c, const Rect.fromLTWH(225, 320, 53, 44), 19, deep);
    final body = Path()
      ..moveTo(200, 126)
      ..cubicTo(126, 126, 88, 172, 86, 251)
      ..cubicTo(80, 330, 122, 352, 200, 353)
      ..cubicTo(278, 352, 320, 330, 314, 251)
      ..cubicTo(312, 172, 274, 126, 200, 126)
      ..close();
    c.drawPath(body, Paint()..color = pink);
    final shade = Path()
      ..moveTo(90, 279)
      ..cubicTo(116, 329, 274, 349, 312, 276)
      ..cubicTo(310, 332, 273, 353, 200, 353)
      ..cubicTo(131, 353, 94, 334, 90, 279)
      ..close();
    c.drawPath(shade, Paint()..color = const Color(0xFFEF98AE));
    ear(c, false, p.ear);
    ear(c, true, -p.ear * .8);
    round(c, const Rect.fromLTWH(176, 136, 48, 13), 6, const Color(0xFFDA7A95));
    round(c, const Rect.fromLTWH(180, 140, 40, 6), 3, ink);
    if (showCoin &&
        !reduced &&
        action == PigAction.receive &&
        time > .04 &&
        time < .47) {
      final u = ((time - .04) / .43).clamp(0.0, 1.0);
      final x = 65 + 135 * u;
      final y = 75 - 55 * math.sin(u * math.pi) + 98 * u * u;
      c.save();
      c.clipRect(const Rect.fromLTRB(0, -80, 400, 144));
      c.translate(x, y);
      c.scale(1 - .73 * math.pow(u, 3).toDouble(), 1.0);
      coin(c, Offset.zero, 23);
      c.restore();
    }
    round(c, const Rect.fromLTWH(176, 146, 48, 4), 2, const Color(0xFFFFC8D5));
    oval(c, const Rect.fromLTWH(110, 239, 37, 21), blush);
    oval(c, const Rect.fromLTWH(253, 239, 37, 21), blush);
    for (final x in [124.0, 134.0, 264.0, 274.0]) {
      line(c, Offset(x, 244), Offset(x - 3, 249), const Color(0xFFFFCBD6), 3.5);
    }
    eye(c, 154, 214, p.eye, p.look, p.lookX);
    eye(c, 246, 214, p.eye, p.look, p.lookX);
    oval(c, const Rect.fromLTWH(159, 230, 82, 55), deep);
    oval(c, const Rect.fromLTWH(159, 226, 82, 53), const Color(0xFFFFBDCA));
    oval(c, const Rect.fromLTWH(179, 242, 10, 21), const Color(0xFFB95E7B));
    oval(c, const Rect.fromLTWH(211, 242, 10, 21), const Color(0xFFB95E7B));
    final mouth = Path()
      ..moveTo(188, 288)
      ..quadraticBezierTo(200, 297 + p.smile * 6, 212, 288);
    if (!reduced && action == PigAction.flyaway && time > .22 && time < .79) {
      oval(c, const Rect.fromLTWH(195, 286, 10, 13), ink);
    } else {
      c.drawPath(
        mouth,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
    if (p.hug > 0) {
      c.save();
      c.translate(200, 319 - p.hug * 12);
      c.scale(p.hug);
      coin(c, Offset.zero, 39);
      c.restore();
    }
    arm(c, false, p.arm, p.hug);
    arm(c, true, p.arm, p.hug);
    c.restore();
    if (!reduced && action == PigAction.flyaway) flyingCoin(c);
    if (!reduced && action == PigAction.complete) {
      final glow = window(time, .35, .85);
      for (var i = 0; i < 4; i++) {
        c.save();
        c.translate(
          i < 2 ? 64 - glow * 10 : 336 + glow * 10,
          153 + (i % 2) * 82 - glow * 15,
        );
        c.scale(glow);
        final star = Path()
          ..moveTo(0, -10)
          ..quadraticBezierTo(2, -2, 9, 0)
          ..quadraticBezierTo(2, 2, 0, 10)
          ..quadraticBezierTo(-2, 2, -9, 0)
          ..quadraticBezierTo(-2, -2, 0, -10);
        c.drawPath(star, Paint()..color = const Color(0xFFE7AE4D));
        c.restore();
      }
    }
    if (guides) {
      final pen = Paint()
        ..color = const Color(0xFF578B85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      c.drawRect(const Rect.fromLTWH(40, 28, 320, 360), pen);
      c.drawLine(const Offset(40, 364), const Offset(360, 364), pen);
      c.drawCircle(const Offset(200, 143), 8, pen);
    }
    c.restore();
  }

  void ear(Canvas c, bool right, double angle) {
    c.save();
    c.translate(right ? 269 : 131, 151);
    c.rotate(right ? -angle : angle);
    if (right) c.scale(-1.0, 1.0);
    final shape = Path()
      ..moveTo(15, -5)
      ..cubicTo(-6, -39, -37, -50, -43, -16)
      ..cubicTo(-47, 8, -58, 29, -38, 37)
      ..cubicTo(-18, 46, -14, 4, 15, -5)
      ..close();
    c.drawPath(shape, Paint()..color = deep);
    final inner = Path()
      ..moveTo(1, -8)
      ..cubicTo(-20, -29, -31, -30, -32, -9)
      ..lineTo(-38, 20)
      ..quadraticBezierTo(-24, 9, 1, -8);
    c.drawPath(inner, Paint()..color = const Color(0xFFF8BDCC));
    c.restore();
  }

  void eye(
    Canvas c,
    double x,
    double y,
    double open,
    double look, [
    double lookX = 0,
  ]) {
    x += lookX;
    if (open < .35) {
      final path = Path()
        ..moveTo(x - 10, y + 1)
        ..quadraticBezierTo(x, y - 10, x + 10, y + 1);
      c.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    } else {
      oval(
        c,
        Rect.fromCenter(
          center: Offset(x, y + look),
          width: 22,
          height: 33 * open,
        ),
        ink,
      );
      oval(
        c,
        Rect.fromCenter(
          center: Offset(x - 3, y - 8 + look),
          width: 7,
          height: 9 * open,
        ),
        const Color(0xFFFFF7EF),
      );
    }
  }

  void flyingCoin(Canvas c) {
    if (time <= .04 || time >= .67) return;
    final rise = ramp(time, .04, .22);
    final flight = ramp(time, .22, .67);
    final center = Offset(200 + 300 * flight, 173 - 95 * rise - 120 * flight);
    c.save();
    if (time < .22) c.clipRect(const Rect.fromLTRB(0, -100, 600, 144));
    c.translate(center.dx, center.dy);
    final wingSize = ramp(time, .13, .24);
    final flap = math.sin(time * math.pi * 32) * .55;
    for (final direction in [-1.0, 1.0]) {
      c.save();
      c.scale(direction * wingSize, wingSize);
      c.translate(17, 0);
      c.rotate(-.25 + flap);
      final wing = Path()
        ..moveTo(0, 5)
        ..cubicTo(10, -23, 31, -24, 34, -19)
        ..quadraticBezierTo(39, -14, 24, -5)
        ..quadraticBezierTo(40, -13, 36, -3)
        ..quadraticBezierTo(35, 2, 23, 5)
        ..quadraticBezierTo(34, 2, 30, 10)
        ..quadraticBezierTo(14, 20, 0, 5)
        ..close();
      c.drawPath(wing, Paint()..color = const Color(0xFFFFFCF3));
      c.drawPath(
        wing,
        Paint()
          ..color = const Color(0xFFD6C8BA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      c.restore();
    }
    coin(c, Offset.zero, 20);
    c.restore();
  }

  void arm(Canvas c, bool right, double lift, double hug) {
    c.save();
    c.translate(right ? 289 - 35 * hug : 111 + 35 * hug, 281 + 15 * hug);
    if (right) c.scale(-1.0, 1.0);
    c.rotate(-lift);
    final path = Path()
      ..moveTo(-5, -10)
      ..cubicTo(11, -17, 26 + hug * 12, -2, 29 + hug * 12, 16)
      ..cubicTo(36, 36, 11, 45, -1, 25)
      ..quadraticBezierTo(-12, 5, -5, -10)
      ..close();
    c.drawPath(path, Paint()..color = deep);
    c.restore();
  }

  void coin(Canvas c, Offset center, double radius) {
    c.drawCircle(
      center + const Offset(0, 3),
      radius,
      Paint()..color = const Color(0xFFD59A37),
    );
    c.drawCircle(center, radius, Paint()..color = const Color(0xFFF5C967));
    c.drawCircle(
      center,
      radius * .8,
      Paint()
        ..color = const Color(0xFFFFE39B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    oval(
      c,
      Rect.fromCenter(
        center: center,
        width: radius * .86,
        height: radius * .58,
      ),
      const Color(0xFFD69B39),
    );
    for (final dx in [-.14, .14]) {
      round(
        c,
        Rect.fromCenter(
          center: center + Offset(radius * dx, 0),
          width: radius * .1,
          height: radius * .25,
        ),
        2,
        const Color(0xFFFFE39B),
      );
    }
  }

  void oval(Canvas c, Rect r, Color color) =>
      c.drawOval(r, Paint()..color = color);
  void round(Canvas c, Rect r, double radius, Color color) => c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    Paint()..color = color,
  );
  void line(Canvas c, Offset a, Offset b, Color color, double width) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  @override
  bool shouldRepaint(PigPainter old) =>
      old.action != action ||
      old.time != time ||
      old.guides != guides ||
      old.reduced != reduced ||
      old.showCoin != showCoin;
}
