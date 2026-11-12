import '../../app/app_strings.dart';
import '../../app/language_controller.dart';
import '../../shared/sound_service.dart';

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../application/records_controller.dart';
import '../backup/backup_page.dart';
import '../../shared/recovery_notice.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key, required this.controller});
  final RecordsController controller;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          key: const Key('helpPage'),
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/characters/wallehog-app-icon.png',
                    width: 34,
                    height: 34,
                    semanticLabel: tr(context, 'Wallehog 应用图标'),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Wallehog', style: AppType.brand)),
              ],
            ),
            const SizedBox(height: 24),
            Text(tr(context, '帮助'), style: AppType.heading),
            if (controller.needsRecovery)
              RecoveryNotice(controller: controller),
            SizedBox(height: 24),
            const _LanguageTile(),
            const _SoundToggle(),
            _HelpItem(
              tr(context, '记录'),
              tr(
                context,
                '首页点 ＋，输入省下的金额，点 ✓ 保存。拖动顶部把手可调整高度，双击把手恢复半屏。支持四则运算和括号，例如 30−12−10−5。备注和日期可以留空，日期默认为今天。',
              ),
            ),
            _HelpItem(
              tr(context, '心愿'),
              tr(
                context,
                '上下滑动循环切换心愿，卡片下方 ＋ 添加心愿，铅笔编辑。新记录默认计入当前心愿，可在备注、日期下方修改绑定；长按记录也可改绑。无心愿也能记录，只有从没有心愿到新增第一个心愿时，未绑定记录才自动计入；已有心愿时新增或切换不会转移记录。名称、金额和样式可修改；清除只删除该心愿，保留记录。',
              ),
            ),
            _HelpItem(
              tr(context, '金额的含义'),
              tr(
                context,
                '这里记录的是你自行报告的节省成果，不代表真实存款、余额或可用资金。心愿进度只是激励，不表示已经具备购买资金。',
              ),
            ),
            _HelpItem(
              tr(context, '修改记录'),
              tr(
                context,
                '首页滚动浏览全部记录；长按记录编辑，向右滑至半行露出删除图标，点击并确认后删除，向左滑可收起。累计金额、心愿进度和小猪成长会随有效记录重新计算。',
              ),
            ),
            _HelpItem(
              tr(context, '小猪的角落'),
              tr(
                context,
                '小猪就住在首页右上角，碰一碰会原地轻跳并说句话。等级按有效记录次数计算，与金额无关；互动不会增加经验，也没有断签惩罚。',
              ),
            ),
            _HelpItem(
              tr(context, '备份'),
              tr(
                context,
                '数据只保存在本机，换手机或卸载前请先导出。备份为明文 JSON；恢复会整体替换当前数据，确认前可预览，建议先备份。',
              ),
            ),
            _HelpItem(
              tr(context, 'GitHub · 支持 Wallehog'),
              tr(
                context,
                '喜欢 Wallehog？欢迎访问 github.com/Naclarb/Wallehog，点一颗 Star 支持后续开发。',
              ),
            ),
            if (controller.supportsBackup)
              IconButton.filledTonal(
                tooltip: tr(context, '备份与恢复'),
                key: const Key('backupEntry'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BackupPage(controller: controller),
                  ),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
              ),
          ],
        ),
      ),
    ),
  );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final language = LanguageScope.maybeOf(context);
    return ListTile(
      key: const Key('languageEntry'),
      contentPadding: EdgeInsets.zero,
      title: Text(tr(context, '语言')),
      subtitle: Text(isEnglish(context) ? 'English' : '简体中文'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: language == null || !language.loaded || language.saving
          ? null
          : () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              constraints: const BoxConstraints(maxWidth: 480),
              backgroundColor: pageBackground,
              builder: (sheetContext) => ListenableBuilder(
                listenable: language,
                builder: (sheetContext, _) => SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '语言 / Language',
                                  style: AppType.heading,
                                ),
                              ),
                              IconButton(
                                tooltip: tr(sheetContext, '关闭'),
                                onPressed: language.saving
                                    ? null
                                    : () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          for (final locale in LanguageController.supported)
                            ListTile(
                              key: Key('language_${locale.languageCode}'),
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                locale == LanguageController.english
                                    ? 'English'
                                    : '简体中文',
                              ),
                              selected: language.locale == locale,
                              trailing: language.locale == locale
                                  ? const Icon(Icons.check_rounded)
                                  : null,
                              enabled: !language.saving,
                              onTap: () async {
                                final saved = await language.select(locale);
                                if (!sheetContext.mounted) return;
                                if (saved) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                            ),
                          const SizedBox(height: 12),
                          if (language.saveFailed) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                tr(sheetContext, '语言设置保存失败，请重试。'),
                                key: const Key('languageSaveError'),
                                style: AppType.caption.copyWith(
                                  color: deepPink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            tr(sheetContext, '语言仅改变显示方式，金额数值不变，不进行汇率换算。'),
                            style: AppType.caption,
                          ),
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

class _HelpItem extends StatelessWidget {
  const _HelpItem(this.title, this.description);
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey('help_$title'),
    shape: const RoundedRectangleBorder(side: BorderSide.none),
    collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 20),
    title: Text(title, style: AppType.title),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(description, style: AppType.body),
      ),
    ],
  );
}

class _SoundToggle extends StatefulWidget {
  const _SoundToggle();
  @override
  State<_SoundToggle> createState() => _SoundToggleState();
}

class _SoundToggleState extends State<_SoundToggle> {
  bool enabled = false;
  bool busy = true;
  @override
  void initState() {
    super.initState();
    SoundService.enabled().then((value) {
      if (mounted) {
        setState(() {
          enabled = value;
          busy = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    key: const Key('soundToggle'),
    contentPadding: EdgeInsets.zero,
    title: Text(tr(context, '音效')),
    subtitle: Text(tr(context, '投币和达成时播放音效')),
    value: enabled,
    onChanged: busy
        ? null
        : (value) async {
            setState(() => busy = true);
            final saved = await SoundService.setEnabled(value);
            if (!mounted) return;
            setState(() {
              if (saved) enabled = value;
              busy = false;
            });
            if (!saved && context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(tr(context, '音效设置保存失败'))));
            }
          },
  );
}
