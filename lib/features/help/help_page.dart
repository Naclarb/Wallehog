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
                    semanticLabel: 'Wallehog 应用图标',
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Wallehog', style: AppType.brand)),
              ],
            ),
            const SizedBox(height: 24),
            Text('帮助', style: AppType.heading),
            if (controller.needsRecovery)
              RecoveryNotice(controller: controller),
            SizedBox(height: 24),
            const _SoundToggle(),
            _HelpItem(
              '记录',
              '首页点 ＋，输入省下的金额，点 ✓ 保存。拖动顶部把手可调整高度，双击把手恢复半屏。支持四则运算和括号，例如 30−12−10−5。备注和日期可以留空，日期默认为今天。',
            ),
            _HelpItem(
              '心愿',
              '上下滑动循环切换心愿，卡片下方 ＋ 添加心愿，铅笔编辑。之后的新记录只计入当前心愿，切换不转移已有进度；无心愿也能记录。名称、金额和样式可修改；清除只删除该心愿，保留记录。',
            ),
            _HelpItem(
              '金额的含义',
              '这里记录的是你自行报告的节省成果，不代表真实存款、余额或可用资金。心愿进度只是激励，不表示已经具备购买资金。',
            ),
            _HelpItem(
              '修改记录',
              '首页滚动浏览全部记录；长按记录编辑，向右滑至半行露出删除图标，点击并确认后删除，向左滑可收起。累计金额、心愿进度和小猪成长会随有效记录重新计算。',
            ),
            const _HelpItem(
              '小猪的角落',
              '小猪就住在首页右上角，碰一碰会原地轻跳并说句话。等级按有效记录次数计算，与金额无关；互动不会增加经验，也没有断签惩罚。',
            ),
            _HelpItem(
              '备份',
              '数据只保存在本机，换手机或卸载前请先导出。备份为明文 JSON；恢复会整体替换当前数据，确认前可预览，建议先备份。',
            ),
            const _HelpItem(
              'GitHub · 支持 Wallehog',
              '喜欢 Wallehog？欢迎在 GitHub 仓库开放后点一颗 Star，支持后续开发。仓库正在筹备，链接将在创建后更新到这里。',
            ),
            if (controller.supportsBackup)
              IconButton.filledTonal(
                tooltip: '备份与恢复',
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
    title: const Text('音效'),
    subtitle: const Text('投币和达成时播放音效'),
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
              ).showSnackBar(const SnackBar(content: Text('音效设置保存失败')));
            }
          },
  );
}
