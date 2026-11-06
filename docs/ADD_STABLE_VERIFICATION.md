# 底栏加号闪烁修复

日期：2026-10-24；对应 DCK07。

本轮用户指出闪烁的是底栏中央加号，不是心愿物件。根因是心愿切换期间将 IconButton.onPressed 设为 null，Flutter 默认禁用态背景变灰、图标变淡，结束后恢复粉色。保留禁止录入及无障碍禁用语义，显式将 disabledBackgroundColor / disabledForegroundColor 设为与正常态相同的 primaryPink / ink，避免状态颜色跳变。帮助页入口保持可用。

自动验证：dart format、flutter analyze、diff 空白检查通过；flutter test 171 项通过。新增实际拖动检查：按钮 Material 渲染背景前中后一致、禁用/正常图标颜色一致、切换中点击不打开计算器、结束后恢复可用并切至正确心愿。日志：.buildlog/add-stable-tests.log、add-stable-analyze.log。

构建与设备验证将在下方记录；无数据库迁移或新依赖。

普通 arm64 release 构建通过（23.9MB，.buildlog/add-stable-release.log）；adb install -r 返回 Success，普通包启动 Status: ok。未卸载、未清数据、未新增或修改用户记录。

CGL-W00 模拟 1080×2340 / 443dpi 手机视口，滑动录屏并以 15fps 检查前 20 帧底栏：加号始终保持粉色与深色图标，无禁用态灰闪。录屏：[滑动与稳定加号](recordings/add-stable.mp4)。已切回原心愿，恢复原始 2032×3048、400dpi、旋转设置 1/1。限制：手机尺寸在平板模拟，未做完整帧耗时或人工 TalkBack 验收。

保留已有未提交工作，未提交混合改动或推送。
