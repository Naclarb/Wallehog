# 卡牌、底栏录入与帮助分区验证

日期：2026-10-24；对应 DCK01–DCK04。

- 顶牌完整移出卡片可见区域后换到后层，再回落到后层位置，第二张卡片上浮。保留上下循环、失败回退、减少动画与切换期间禁止录入。
- 首页加号位于手机底栏中央；平板沿用侧栏主操作。
- 计算器默认三分之一屏，顶部把手拖动可调整至约 90%，双击恢复默认；本次进程内记忆，不写库。紧凑五列四行键盘，额外字段滚动显示。补齐高度调节读屏状态值。
- 帮助主题默认折叠、点击展开；备份入口保留。GitHub / Star 区块明确仓库筹备中，建仓后填真实链接。
- dart format 与 flutter analyze 通过；flutter test 165 项通过。新增中央入口位置、默认高度、拖高、双击复位、帮助展开和仓库状态检查；旧帮助测试同步为先展开正文。
- 普通 arm64 release APK 构建通过（23.9MB）；adb install -r 返回 Success，dev.wallehog.wallehog/.MainActivity 启动 Status: ok。未卸载、未清数据、未保存或删除日常记录。
- CGL-W00 以 1080×2340、443dpi 模拟手机检查首页、完整紧凑键盘和折叠帮助。截图：screenshots/deck-home.png、deck-calculator.png、deck-help.png。原始 2032×3048、400dpi、user_rotation=1、accelerometer_rotation=1 已恢复。
- 限制：未在独立手机硬件验收；本轮未完成卡牌逐帧真机录屏或人工 TalkBack 全路径验证。高度重启后恢复默认。GitHub 仓库未创建，尚无真实仓库跳转。
- 保留已有混合未提交工作，未暂存父仓库文件、未提交或推送。
