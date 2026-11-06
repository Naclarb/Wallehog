# 首页细节打磨 v1.6

日期：2026-10-24；需求 R01–R05。保留已有 Goal、右上角小猪、累计节省、最近记录与导航构图。

## 已完成

- P0：手机 Goal 最小高度 300→276dp，厚叠层尾部 14→4dp；品牌后、Goal 后和摘要后间距收紧；记录行减少上下内边距，保留至少 48dp 的标准触碰高度。导航内容 64→56dp，加系统安全区。
- P1：两层实体色板改为单层低对比提示，保留相邻卡露出；主体柔影、渐隐白色内高光与收紧的物件柔影营造完整面板。白环笔画 7→4.5dp，终点使用小型双色圆标。PS5 图像仍 128dp，环外径仍 165dp。无新增素材、循环漂浮或粒子装饰。
- 字体：累计金额 34sp/700，心愿金额 16sp/600，记录金额 14sp/700，仅收敛首页字体，不改计算器和历史页面的样式。
- P2：Goal、顶部小猪及 Add 采用 420ms 节奏，成功新增并重读后才播放保存回应。保留原成功/升级提示；失败不触发成功反馈；减少动画时小猪与 Add 静态呈现，Goal 立即显示真实值。新增控制器按生命周期释放。
- 不改领域规则、记录归属、备份、数据库或依赖。

## 已执行验证

- 格式检查通过（`.buildlog/refine16-format.log`）；静态分析无问题（`.buildlog/refine16-final-analyze.log`）。
- 全套 148 项通过（`.buildlog/refine16-final-tests.log`）。新增测试在 360×800、390×844、上下各 24dp 安全区域下，验证三笔记录无需滚动即可完整显示，且手柄仍为 128dp；验证保存失败、重试成功、顶部小猪及 Add 的同步回应、减少动画与归位。保留长文本、大字体、平板、金额与迁移、备份、成长和幂等回归。
- Android debug 集成入口构建成功（`.buildlog/refine16-test-build.log`）。

## 设备与截图

设备 CGL-W00 / Android 16。原值：2032×3048、density=400、user_rotation=1、accelerometer_rotation=1。390dp 手机视口临时 1080×2340 / density=443，360dp 追加使用 1080×2400 / density=480。测试仅使用 `.uitest` 沙盒；每轮 finally 恢复原参数。

390dp 原生运行器完成 2 项、0 失败、0 跳过，BUILD SUCCESSFUL（`.buildlog/refine16-device.log`）；360dp 再次执行 `OK (2 tests)`，37.26 秒（`.buildlog/refine16-device-360.log`）。涵盖真实 SQLite、计算器、编辑删除、重启、多心愿与备份往返。

已目视检查手机截图，三笔最近记录完整展示，手柄保持原尺寸。新旧对比使用同一独立测试数据，不是日常应用数据：

- [同数据新旧对比](screenshots/refine16-comparison.html)
- [390dp · 三笔记录](screenshots/refine16-ps5-three.png)
- [360dp · 三笔记录](screenshots/refine16-360-ps5-three.png)
- [耳机](screenshots/refine16-headphones.png)、[相机](screenshots/refine16-camera.png)

完整清理构建缓存后，普通 `lib/main.dart` arm64 release 构建成功，42.5 秒、23.9MB（`.buildlog/refine16-release.log`）。`adb install -r` 返回 `Success`，启动普通包 `dev.wallehog.wallehog/.MainActivity` 返回 `Status: ok`、`LaunchState: COLD`，前台 Activity 复查为普通应用。已目视检查日常首页可读取原有记录、心愿与金额；未卸载、清空数据或修改用户心愿。显示参数复查与原值一致。

## 限制

手机视口使用平板临时尺寸近似，非独立手机硬件；没有人工 TalkBack 验收。大字体与长标题仍允许滚动，不承诺三笔记录在任意字号下同时显示。release 使用现有开发签名。

保留原有未提交工作；未提交或推送父仓库。
