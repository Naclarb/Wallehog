# 首页冻结与核心投币反馈 v1.7

日期：2026-10-24；需求 F01–F04。保留页面结构、配色、字体、现有素材、手柄与圆环构图，无新业务功能、依赖或数据库迁移。

## 本轮改动

- 顶部检查：单层 SafeArea 加手机顶部 4dp，没有额外状态栏 padding；保留安全区域。
- 三张心愿保留原 PageView 尺寸和侧边露出，增加预览箭头与点击切换。仅明确拖动或箭头点击结束后才持久化选择，窗口尺寸变化不写入当前选择；防止跨多张卡片时选中状态与画面不同步。创建、切换与原归属规则不变。
- 成功反馈改为可穿透点击的局部层，放大复用原猪。前 550ms 金币弧线飞向素材投币口并缩小消失，之后 350ms 小猪轻跳、鼓励语显现。2.3 秒后收起；再次 Add 立即清除，旧异步反馈失效。
- 累计金额 700ms 平滑过渡；Goal 保留真实进度动画。Add 按下缩小 6%，抬起/取消回弹；计算器 280ms 弹出、220ms 关闭。减少动画时直接呈现静态结果。
- 成功事件仍只来自数据库提交且一致快照读取成功的计算器返回。失败保留输入、不庆祝；已提交但读取失败仍只能重试读取，避免重复记录。

## 验证

- Dart 格式检查、flutter analyze 无问题；全套 150 项测试通过（`.buildlog/freeze17-tests.log`、`freeze17-analyze.log`）。覆盖失败/重试、减少动画、快速重复保存、控制器释放、金币先于鼓励语、三心愿预览点击、滑动与尺寸切换保持选择；原金额、迁移、归属、备份及大小字体/平板回归保持通过。
- Android debug 测试构建成功（`freeze17-device-build.log`）。原生运行器在 390dp 手机视口完整流程通过：`OK (1 test)`、15.699 秒（`freeze17-device.log`）。360dp 同一测试 `OK (1 test)`、15.523 秒（`freeze17-device-360.log`）。使用真实 SQLite 独立数据库，仅测试沙盒生成 PS5/耳机/相机，不修改日常数据。
- [实际 Android 录屏](recordings/core-feedback-android.mp4)：约 13.2 秒，1080×2340；展示 Add、逐键输入 27、保存、金币入槽、小猪回应、随机鼓励语、累计 ¥0→¥27 与 Goal ¥0→¥27，以及三张心愿切换后返回 PS5。原始 adb screenrecord 持续渲染；仅裁去前后桌面片段，未变速、拼接或合成动画。已检查 100ms 间隔反馈帧，见本地 `freeze17-coin-frames.png`。
- 普通 `lib/main.dart` arm64 release 构建成功，23.9MB（`freeze17-release.log`）。`adb install -r` 返回 Success，普通包 `dev.wallehog.wallehog/.MainActivity` 冷启动 Status: ok；未卸载或清空数据，原累计 ¥714.00 与两个心愿可读取。

## 设备与限制

CGL-W00 / Android 16 平板使用手机逻辑视口，并非独立手机硬件。原值 2032×3048、density=400、user_rotation=1、accelerometer_rotation=1；录屏临时 1080×2340 / density=443。另检查 360dp（1080×2400 / density=480）。完成后恢复原始显示与旋转设置并回到普通应用。

release 沿用现有开发签名。无人工 TalkBack 验收。本轮保留此前未提交工作，未暂存或推送父仓库。
