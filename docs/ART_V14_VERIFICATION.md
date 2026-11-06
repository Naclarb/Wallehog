# 首页美术精修 v1.4

日期：2026-10-24。需求 H01–H03；用户提供的概念图只作为视觉灵感。

## 设计

- 保留心愿、累计节省、最近记录的顺序及右上角小猪入口。
- 心愿场景采用三段柔粉径向渐变，礼物下方增加柔影，真实白色进度弧增加轻投影；保留原创礼物和猪，不新增图片或依赖。
- 品牌标识有浅粉圆角底；角落入口采用现有猪缩略图，保留“ 小猪的角落 ”按钮语义。深色底栏顶部圆角，选中项增加半透明背景；圆形加号降低阴影强度。
- 最近记录与标题左对齐，图标增加浅粉细边；金额继续正向展示，点击沿用原编辑流程。
- Q01–Q10、数据与迁移、计算器、成长和备份规则不变。

## 已执行验证

- Dart 格式化完成。
- `flutter analyze`：No issues found；日志 `.buildlog/art-v14-analyze.log`。
- `flutter test`：136 项通过；含 390×844、360×800、空心愿、长文本/大字体、600dp 断点、平板横竖屏与运行时缩放，以及金额、迁移、幂等和成长回归；日志 `.buildlog/art-v14-tests.log`。
- 普通 arm64 release 构建成功，20.2MB；日志 `.buildlog/art-v14-release.log`。
- Android 集成测试入口 debug 构建成功；日志 `.buildlog/art-v14-test-build.log`。

## 设备检查

设备 CGL-W00 / Android 16；测试前原始参数：2032×3048、density=400、user_rotation=1、accelerometer_rotation=1。测试使用独立 `.uitest`，临时手机视口 1080×2340、density=443，结束通过 finally 恢复原参数。测试数据不写入日常应用。

390dp 手机视口完整 records 集成流程通过：1 项完成、0 失败、0 跳过，Gradle BUILD SUCCESSFUL；日志 `.buildlog/art-v14-device.log`。360×800dp 视口（1080×2400、density=480）使用原生运行器再次执行，`OK (1 test)`，27.41 秒；日志 `.buildlog/art-v14-device-360.log`。覆盖真实 SQLite 录入、重启、编辑删除、心愿边界、小猪触碰与备份往返。

已逐张目视检查真实 Flutter 截图：

- [390dp 首页](screenshots/art-v14-ui-home.png)
- [390dp 无心愿](screenshots/art-v14-ui-no-goal.png)
- [360dp 首页](screenshots/art-v14-360-ui-home.png)

普通应用 `adb install -r build/app/outputs/flutter-apk/app-release.apk` 返回 `Success`；启动 `dev.wallehog.wallehog/.MainActivity` 返回 `Status: ok`、`LaunchState: COLD`。未卸载或清空数据。安装后复查设备尺寸 2032×3048、density=400、旋转两项均为 1，与原值一致。

## 限制

手机硬件体验使用平板临时手机逻辑视口近似；未执行人工 TalkBack 验收。素材复用已有资产，本轮未重绘角色。release 仍使用开发签名。

工作区已有大量未提交工作，本轮保留既有修改，未自动提交或推送父仓库。
