import 'dart:math';

/// 随应用打包的本地台词；互动不产生记录或经验。
class PigRoomLines {
  static const pats = [
    '慢慢来，每一个小选择都值得珍惜。',
    '谢谢你来摸摸我，今天也对自己温柔一点。',
    '你已经做得很好啦，我陪着你。',
    '不必着急，我们按自己的节奏来。',
  ];
  static const talks = [
    '见到你真好，来这里歇一会儿吧。',
    '小小的开心，也值得被收藏。',
    '喜欢的生活，可以一步一步靠近。',
    '今天没有记录也没关系，我在这里陪你。',
  ];
  final Random _random = Random();
  String pick(List<String> lines) => lines[_random.nextInt(lines.length)];
}
