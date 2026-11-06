import 'dart:math';

/// 本地反馈规则，不参与金额、目标或存储计算。
enum EncouragementScene {
  normal,
  nearGoal,
  completed,
  welcomeBack,
  firstSaving,
  halfway,
}

EncouragementScene encouragementScene({
  required bool completed,
  required double fraction,
  required bool returning,
}) {
  if (completed) return EncouragementScene.completed;
  if (returning) return EncouragementScene.welcomeBack;
  if (fraction >= .8 && fraction < 1) return EncouragementScene.nearGoal;
  return EncouragementScene.normal;
}

class Encouragements {
  static const lines = <EncouragementScene, List<String>>{
    EncouragementScene.firstSaving: ['这是我们一起存下的第一个小进步 ♡', '小猪记住这一刻啦，慢慢来就好。'],
    EncouragementScene.halfway: ['一点一点，心愿已经走到一半啦！', '回头看，我们已经走了这么远 ♡'],
    EncouragementScene.normal: ['叮！小确幸入袋啦 ♡', '这枚金币，我替你抱好！', '小猪收到，快乐加一！'],
    EncouragementScene.nearGoal: ['心愿越来越近，猪鼻子都闻到啦！', '再近一点点，期待冒泡啦！'],
    EncouragementScene.completed: ['心愿进度达成！每一个小选择，都算数 ♡', '心愿亮灯！小猪为你撒花 ♡'],
    EncouragementScene.welcomeBack: ['嘿，你回来啦！猪猪给你留了位置 ♡', '好久不见，接住这份小开心！'],
  };
  final Random _random;
  String? _last;
  Encouragements({Random? random}) : _random = random ?? Random();
  String pick(EncouragementScene scene) {
    final options = lines[scene]!;
    final available = options.where((line) => line != _last).toList();
    final picked = available[_random.nextInt(available.length)];
    _last = picked;
    return picked;
  }
}
