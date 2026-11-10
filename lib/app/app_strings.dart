import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.english);
  final bool english;
  static const delegate = _AppStringsDelegate();
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale.languageCode == 'en'));

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

bool isEnglish(BuildContext context) =>
    Localizations.of<AppStrings>(context, AppStrings)?.english ?? false;

/// Display notation only. Stored amounts and CNY backup data are unchanged.
String currencySymbol(BuildContext context) => isEnglish(context) ? r'$' : '¥';

/// Localize built-in copy only; never pass user-written notes or wish names.
/// Domain validation stays pure Dart and is translated at the UI boundary.
String tr(
  BuildContext context,
  String message, [
  List<Object?> values = const [],
]) {
  final template = isEnglish(context)
      ? englishMessages[message] ?? message
      : message;
  return template.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
    final index = int.parse(match[1]!);
    return index < values.length ? '${values[index]}' : match[0]!;
  });
}

const englishMessages = <String, String>{
  '语言': 'Language',
  '语言设置保存失败，请重试。': 'Could not save the language. Please try again.',
  '语言仅改变显示方式，金额数值不变，不进行汇率换算。':
      'Language changes display notation only. Amounts stay the same; no currency conversion is applied.',
  'GitHub · 支持 Wallehog': 'GitHub · Support Wallehog',
  'Lv.5 已满级，继续收藏你的小确幸': 'Lv.5 reached. Keep collecting little wins.',
  'Wallehog 应用图标': 'Wallehog app icon',
  '一次值得记住的选择 · 未计金额': 'A choice to remember · No amount recorded',
  '一次好选择': 'One good choice',
  '上一个心愿': 'Previous wish',
  '下一个心愿': 'Next wish',
  '例如：(20 + 10) / 2': 'Example: (20 + 10) / 2',
  '例如：带水杯出门，少买一杯饮料': 'Example: Brought water instead of buying a drink',
  '保存中': 'Saving',
  '保存好选择': 'Save choice',
  '保存心愿': 'Save wish',
  '保存节省金额': 'Save savings',
  '保留': 'Keep',
  '修改记录': 'Edit records',
  '关闭': 'Close',
  '再有 {0} 次好选择，遇见 Lv.{1}': '{0} more good choices to reach Lv.{1}',
  '创建心愿': 'Create wish',
  '删除': 'Delete',
  '删除后无法撤销。': 'This cannot be undone.',
  '删除后，已节省金额和好选择次数会重新计算。此操作不能撤销。':
      'Savings and good choices will be recalculated. This cannot be undone.',
  '删除记录': 'Delete record',
  '删除这个选择？': 'Delete this choice?',
  '删除这笔记录？': 'Delete this record?',
  '升级啦！Lv.{0}': 'Level up! Lv.{0}',
  '原选项价格（元）': 'Original price',
  '又一个小确幸，小猪收到啦 ♡': 'Another little win, safely tucked away ♡',
  '发生日期：{0}': 'Date: {0}',
  '取消': 'Cancel',
  '取消预览': 'Close preview',
  '只清除这个心愿，所有记录仍会保留，不会转入其他心愿。':
      'Only this wish will be removed. All records will be kept and will not move to another wish.',
  '喜欢 Wallehog？欢迎在 GitHub 仓库开放后点一颗 Star，支持后续开发。仓库正在筹备，链接将在创建后更新到这里。':
      'Enjoying Wallehog? Give it a Star when the GitHub repository opens. The repository is being prepared; its link will appear here when available.',
  '填写做决定前已确定的预算，而不是事后设定的金额。':
      'Use the budget you set before making the choice.',
  '填写原计划购买选项的价格，与实际替代品比较。':
      'Compare the original planned price with what you paid for the alternative.',
  '备份': 'Backup',
  '备份与恢复': 'Backup & restore',
  '备份已保存到你选择的位置。': 'Backup saved to your chosen location.',
  '导出当前数据': 'Export current data',
  '备份日期：{0}': 'Backup date: {0}',
  '备注': 'Note',
  '备注、日期与心愿': 'Note, date & wish',
  '备注与日期': 'Note & date',
  '实际支出（元）': 'Actual spending',
  '导出全部记录与当前心愿，换手机时可在 Wallehog 中恢复。备份是未加密的 JSON 文件，请保存到自己信任的位置。':
      'Export all records and wishes to restore in Wallehog on another phone. Backups are unencrypted JSON files. Save them somewhere you trust.',
  '小猪就住在首页右上角，碰一碰会原地轻跳并说句话。等级按有效记录次数计算，与金额无关；互动不会增加经验，也没有断签惩罚。':
      'Your pig lives at the top right of Home. Tap for a little hop and a friendly word. Levels reflect valid records, regardless of amount. Interactions add no experience, and there are no missed-day penalties.',
  '小猪成长进度': 'Pig growth progress',
  '小猪的角落': 'Piggy corner',
  '小猪，等级 {0}，摸摸小猪': 'Pig, level {0}. Tap to say hello.',
  '尚未设置心愿': 'No wish set yet',
  '已取消导出。': 'Export cancelled.',
  '已取消选择。': 'File selection cancelled.',
  '已积累 100%': 'Progress 100%',
  '已积累 {0}%': 'Progress {0}%',
  '已经做了 {0} 次好选择': '{0} good choices so far',
  '已节省金额 +{0}0.00 · 好选择 +1 次\n放弃购买不会自动折算成节省金额。':
      'Savings +{0}0.00 · Good choices +1\nSkipping a purchase does not automatically count as savings.',
  '已记录 {0}': 'Recorded {0}',
  '已记录 {0}，{1}': 'Recorded {0}. {1}',
  '帮助': 'Help',
  '当前 {0} 笔记录和心愿将被替换为备份中的 {1} 笔记录与心愿，不会合并。此操作不能撤销。\n\n建议先返回导出当前数据。':
      'Your current {0} records and wishes will be replaced with {1} records and wishes from the backup. They will not be merged. This cannot be undone.\n\nConsider going back to export your current data first.',
  '当前心愿：{0}\n激励进度：{1}{2} / {3}{4}':
      'Current wish: {0}\nProgress: {1}{2} / {3}{4}',
  '当前心愿：无': 'Current wish: None',
  '心愿': 'Wish',
  '心愿名称': 'Wish name',
  '心愿激励进度 {0}%': 'Wish progress {0}%',
  '心愿进度已达成': 'Wish progress complete',
  '心愿：{0} 个': 'Wishes: {0}',
  '恢复会整体替换当前数据，不会合并。选择文件仅预览，不会立即修改记录。最多 10 MiB / 50,000 笔。':
      'Restore replaces all current data; it does not merge. Selecting a file only opens a preview. Limit: 10 MiB / 50,000 records.',
  '恢复失败，原有数据已保留。': 'Restore failed. Your original data has been kept.',
  '恢复完成，记录与心愿已更新。': 'Restored. Records and wishes have been updated.',
  '恢复预览': 'Restore preview',
  '把小确幸，慢慢变成大期待': 'Little wins, growing into something to look forward to',
  '投币和达成时播放音效': 'Play sounds for coins and milestones',
  '摸摸小猪': 'Say hello to your pig',
  '支持 + - * / 和括号': 'Supports + - * / and parentheses',
  '数据只保存在本机，换手机或卸载前请先导出。备份为明文 JSON；恢复会整体替换当前数据，确认前可预览，建议先备份。':
      'Data stays on this device. Export before changing phones or uninstalling. Backups are plain-text JSON. Restore replaces all current data, with a preview before confirmation. Back up first.',
  '数据已恢复，但读取失败。请重新读取，无需再次恢复。':
      'Data was restored, but could not be read. Reload without restoring again.',
  '文件操作失败，请重试。': 'File operation failed. Please try again.',
  '文件操作暂未完成，请重试。当前记录未被替换。':
      'File operation could not be completed. Please try again. Current records have not been replaced.',
  '既定预算（元）': 'Planned budget',
  '旧版记录：确认后改为直接记录金额，原比较依据不再保留。':
      'Legacy record: saving converts it to a direct savings amount. The original comparison will not be kept.',
  '暂无心愿，创建第一个心愿后自动计入。':
      'No wishes yet. Unbound records will count toward your first wish.',
  '暂无记录': 'No records yet',
  '未绑定': 'Unbound',
  '本地数据库暂时无法打开，数据不会被自动清除。':
      'The local database could not be opened. Your data will not be cleared.',
  '正在保存': 'Saving',
  '正在保存…': 'Saving…',
  '正在唤醒小猪…': 'Waking up your pig…',
  '正在读取…': 'Loading…',
  '正在读取成长状态…': 'Loading growth…',
  '比较基准需要大于实际支出。': 'The comparison amount must exceed actual spending.',
  '添加心愿': 'Add wish',
  '清空': 'Clear',
  '清除': 'Remove',
  '清除心愿': 'Remove wish',
  '清除心愿？': 'Remove this wish?',
  '用备份替换当前数据？': 'Replace current data with this backup?',
  '目标金额': 'Target amount',
  '目标金额，元': 'Target amount',
  '省钱成果 +{0}{1}': 'Savings +{0}{1}',
  '确认删除': 'Confirm deletion',
  '确认替换': 'Confirm replacement',
  '累计省钱成果：{0}{1}': 'Total savings: {0}{1}',
  '累计节省': 'Total saved',
  '绑定心愿': 'Linked wish',
  '给小猪一个期待': 'A wish to look forward to',
  '继续恢复': 'Continue restore',
  '编辑': 'Edit',
  '编辑好选择': 'Edit choice',
  '编辑心愿': 'Edit wish',
  '编辑记录': 'Edit record',
  '节省差额 {0}{1} · 好选择 1 次': 'Savings {0}{1} · Good choices 1',
  '节省金额算式': 'Savings expression',
  '记录': 'Records',
  '记录一个好选择': 'Record a good choice',
  '记录的节省成果，不代表实际存款或可用资金。':
      'Self-reported savings, not actual deposits or available funds.',
  '记录节省': 'Record savings',
  '记录：{0} 笔': 'Records: {0}',
  '设置心愿': 'Set a wish',
  '请填写心愿名称和正数目标金额': 'Enter a wish name and a positive target amount.',
  '请重新读取最新数据后继续，不会重复提交。':
      'Reload the latest data to continue. Nothing will be submitted twice.',
  '读取失败，请重试。': 'Could not load data. Please try again.',
  '读取完成。': 'Data loaded.',
  '调整计算器高度': 'Adjust calculator height',
  '返回': 'Back',
  '还没有记录，从一个小选择开始。': 'No records yet. Start with one little choice.',
  '这个选择是什么？': 'What was your choice?',
  '这里记录的是你的选择，不是实际存款。': 'These are your choices, not actual deposits.',
  '这里记录的是你自行报告的节省成果，不代表真实存款、余额或可用资金。心愿进度只是激励，不表示已经具备购买资金。':
      'These are self-reported savings, not actual deposits, balances or available funds. Wish progress is encouragement, not proof that a purchase is affordable.',
  '退格': 'Backspace',
  '选择备份，预览恢复': 'Choose a backup to preview',
  '选择类型': 'Choice type',
  '选择记录': 'Choice history',
  '重新读取': 'Reload',
  '重新读取并返回，确认记录后再继续':
      'Reload and return. Check your records before continuing.',
  '重试': 'Retry',
  '重试清除': 'Retry removal',
  '重试读取': 'Retry loading',
  '重试读取已保存记录': 'Reload saved records',
  '金额的含义': 'What the amounts mean',
  '金额需要大于零': 'Amount must be greater than zero',
  '陪伴你的小猪': 'Your pig companion',
  '音效': 'Sound effects',
  '音效设置保存失败': 'Could not save the sound setting',
  '首页': 'Home',
  '首页滚动浏览全部记录；长按记录编辑，向右滑至半行露出删除图标，点击并确认后删除，向左滑可收起。累计金额、心愿进度和小猪成长会随有效记录重新计算。':
      'Scroll Home to see all records. Long-press to edit, or swipe right halfway to reveal Delete. Tap and confirm to delete; swipe left to close. Totals, wish progress and pig growth reflect your valid records.',
  '首页点 ＋，输入省下的金额，点 ✓ 保存。拖动顶部把手可调整高度，双击把手恢复半屏。支持四则运算和括号，例如 30−12−10−5。备注和日期可以留空，日期默认为今天。':
      'Tap +, enter what you saved, then tap ✓. Drag the top handle to resize the calculator; double-tap to reset to half height. Arithmetic and parentheses are supported, for example 30−12−10−5. Notes are optional; the date defaults to today.',
  '上下滑动循环切换心愿，卡片下方 ＋ 添加心愿，铅笔编辑。新记录默认计入当前心愿，可在备注、日期下方修改绑定；长按记录也可改绑。无心愿也能记录，只有从没有心愿到新增第一个心愿时，未绑定记录才自动计入；已有心愿时新增或切换不会转移记录。名称、金额和样式可修改；清除只删除该心愿，保留记录。':
      'Swipe up or down to cycle wishes. Use + below the card to add one, or the pencil to edit. New records default to the current wish. Change the linked wish below Note and Date, or long-press a record to edit its link. You can record without a wish. Only creating the first wish when none exist adopts unbound records; adding or switching other wishes does not move records. Names, amounts and styles can be edited. Removing a wish keeps its records.',
  '上下滑动循环切换心愿，卡片下方 ＋ 添加心愿，铅笔编辑。之后的新记录只计入当前心愿，切换不转移已有进度；无心愿也能记录。名称、金额和样式可修改；清除只删除该心愿，保留记录。':
      'Swipe up or down to cycle wishes. Use + below the card to add one, or the pencil to edit. New records count toward the current wish; switching does not transfer progress. You can record without a wish. Names, amounts and styles can be edited. Removing a wish keeps its records.',
  '低于既定预算': 'Under planned budget',
  '选择便宜替代': 'Choose a cheaper alternative',
  '放弃可选购买': 'Skip an optional purchase',
  '通用心愿': 'Any wish',
  '自由心愿': 'Any wish',
  'PS5 游戏机': 'PS5 console',
  '一副好耳机': 'Headphones',
  '我的相机': 'My camera',
  '旅行探索': 'Travel and exploration',
  '服饰穿搭': 'Clothing and style',
  '阅读学习': 'Reading and learning',
  '耳机': 'Headphones',
  '相机': 'Camera',
  '存下一个小确幸': 'A little win saved',
  '第一枚金币，收到啦': 'Your first coin, safely tucked away',
  '心愿已经走过一半': 'Halfway to your wish',
  '心愿进度达成！': 'Wish progress complete!',
  '初次见面，陪你从一个小选择开始': 'Nice to meet you. Let us start with one little choice.',
  '慢慢相识，每一点进步都值得被看见': 'Getting to know each other. Every little step matters.',
  '渐渐熟悉，小猪记得你的每一份用心': 'Growing closer. Your pig remembers your care.',
  '一路陪伴，把小确幸慢慢变成大期待':
      'Together, turning little wins into something to look forward to.',
  '慢慢来，每一个小选择都值得珍惜。': 'Take your time. Every little choice counts.',
  '谢谢你来摸摸我，今天也对自己温柔一点。': 'Thanks for saying hello. Be kind to yourself today.',
  '你已经做得很好啦，我陪着你。': 'You are doing well. I am here with you.',
  '不必着急，我们按自己的节奏来。': 'No rush. We can go at our own pace.',
  '见到你真好，来这里歇一会儿吧。': 'Good to see you. Stay and rest a little.',
  '小小的开心，也值得被收藏。': 'Little joys are worth keeping too.',
  '喜欢的生活，可以一步一步靠近。': 'Step by step, toward the life you love.',
  '今天没有记录也没关系，我在这里陪你。': 'No record today? That is okay. I am still here.',
  '这是我们一起存下的第一个小进步 ♡': 'Our first little step together ♡',
  '小猪记住这一刻啦，慢慢来就好。': 'I will remember this moment. Take your time.',
  '一点一点，心愿已经走到一半啦！': 'Little by little, we are halfway there!',
  '回头看，我们已经走了这么远 ♡': 'Look how far we have come ♡',
  '叮！小确幸入袋啦 ♡': 'A little win, tucked away ♡',
  '这枚金币，我替你抱好！': 'I will keep this coin safe for you!',
  '小猪收到，快乐加一！': 'Got it! One more little joy!',
  '心愿越来越近，猪鼻子都闻到啦！': 'Your wish is getting closer. I can sense it!',
  '再近一点点，期待冒泡啦！': 'A little closer. So much to look forward to!',
  '心愿进度达成！每一个小选择，都算数 ♡': 'Wish progress complete! Every little choice counts ♡',
  '心愿亮灯！小猪为你撒花 ♡': 'Your wish is shining. Time to celebrate ♡',
  '嘿，你回来啦！猪猪给你留了位置 ♡': 'Welcome back! I saved you a spot ♡',
  '好久不见，接住这份小开心！': 'Good to see you again. Here is a little joy!',
  '数据已保存，但暂时无法读取最新结果。请重新读取后继续，不会重复提交。':
      'Your data was saved, but the latest results could not be read. Reload to continue. Nothing will be submitted twice.',
  '请先读取本地数据后继续。': 'Load local data before continuing.',
  '本地操作暂未完成，请重试。输入已保留。':
      'The local operation could not be completed. Please try again. Your input has been kept.',
  '导出失败，请重试': 'Export failed. Please try again.',
  '请输入金额算式，最多 128 个字符': 'Enter an amount or expression, up to 128 characters.',
  '金额不能为负数': 'Amount cannot be negative.',
  '单项金额不能超过 9,999,999.99 元': 'Amount cannot exceed 9,999,999.99.',
  '不能除以零': 'Cannot divide by zero.',
  '算式中间结果过大，请简化': 'Intermediate result is too large. Simplify the expression.',
  '算式包含不支持的字符或缺少运算符': 'Unsupported character or missing operator.',
  '括号最多嵌套 32 层': 'Parentheses cannot be nested more than 32 levels.',
  '请补全右括号': 'Add the closing parenthesis.',
  '请输入有效数字，如 12.50 或 (20 + 10) / 2':
      'Enter a valid number, such as 12.50 or (20 + 10) / 2.',
  '小数点后需要数字': 'Add digits after the decimal point.',
  '请用 1–200 个字符描述这个选择': 'Describe your choice in 1–200 characters.',
  '记录编号无效': 'Invalid record ID.',
  '请选择有效的发生日期，不能晚于今天': 'Choose a valid date no later than today.',
  '修改时间不能早于创建时间': 'Modification time cannot precede creation time.',
  '请输入大于零的节省金额': 'Enter savings greater than zero.',
  '旧类型不能直接指定节省金额': 'Legacy types cannot specify a direct savings amount.',
  '放弃购买只计好选择，不记录金额':
      'Skipping a purchase counts as a good choice without an amount.',
  '比较基准须大于实际支出；金额必须在有效范围内':
      'The comparison must exceed actual spending. Amounts must be within range.',
  '累计金额不能为负数': 'Total savings cannot be negative.',
  '累计金额超出本地存储范围': 'Total savings exceed the local storage limit.',
  '备份格式无效、版本不支持或数据超出范围，请选择完整的 Wallehog 备份。':
      'Invalid, unsupported or out-of-range backup. Choose a complete Wallehog backup.',
  '备份不能超过 10 MiB。': 'Backup cannot exceed 10 MiB.',
  '请填写 1–60 字的心愿名称': 'Enter a wish name with 1–60 characters.',
  '请填写有效的正数目标金额': 'Enter a valid positive target amount.',
  '心愿样式或记录归属无效': 'Invalid wish style or record link.',
  '心愿已不存在，请重新选择': 'This wish no longer exists. Choose another.',
  '这次选择可能已保存，请重新读取记录确认':
      'This choice may already be saved. Reload records to check.',
  '记录已不存在，请刷新后重试': 'This record no longer exists. Reload and try again.',
  '创建时间和记录身份不能修改': 'Creation time and record identity cannot be changed.',
  '最多保留 50 个心愿': 'You can keep up to 50 wishes.',
  '心愿已不存在': 'This wish no longer exists.',
  '另一个文件操作尚未完成': 'Another file operation is still in progress.',
  '无法打开系统文件选择器，请重试': 'Could not open the file picker. Please try again.',
  '文件操作失败，请检查文件、可用空间及 10 MiB 大小限制':
      'File operation failed. Check the file, free space and the 10 MiB size limit.',
};
