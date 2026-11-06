# 小猪角落收敛 v1.3

## v1.3.1 位置纠正

普通release构建成功（20.2MB），`adb install -r`返回Success，已启动日常应用，保留数据；日志 `.buildlog/corner-v131-release.log`。

用户明确角落应位于首页右上角原入口。已移除手机底栏/平板侧栏中的小猪导航项，恢复品牌栏右侧小猪按钮，直接展开小猪气泡面板；不跳入独立页面。导航仅首页、历史、帮助，心愿和备份入口不变。

静态分析通过，136项widget/领域/存储回归通过；新增首页右上角坐标检查，适配原互动与导航测试。日志 `.buildlog/corner-v131-analyze.log`、`.buildlog/corner-v131-tests.log`。Android debug测试入口构建成功，日志 `.buildlog/corner-v131-test-build.log`。

390dp手机视口真机完整records流程通过（1项、0失败、BUILD SUCCESSFUL），包含右上角展开面板、触碰不改金额/次数、关闭回首页及原编辑删除/备份回归，日志 `.buildlog/corner-v131-device.log`。测试后恢复原设备尺寸、密度和旋转设置。已目视检查[首页右上角入口](screenshots/corner-v131-ui-home.png)与[直接展开的小猪面板](screenshots/corner-v131-ui-pig-corner.png)。真机硬件及人工验收限制同下文。

2026-10-23，用户授权 K01–K04。

## 当前行为

- 首页不再有重复设置弹层。手机、平板导航直接展示“小猪的角落”，无二次详情页。
- 角落仅保留本地消息气泡、现有小猪与简短等级；移除互动按钮和重复的成长进度/说明。初始台词自然出现，触碰小猪轻跳并换句，不产生经验或记录；减少动画时静态回应。
- 心愿卡铅笔打开统一编辑框，可编辑或清除；清除二次确认，取消不修改，保留所有记录。失败可重试；已提交后读取失败只重读。
- 帮助页直接提供备份与恢复按钮，保留原备份预览、整体替换确认和数据校验。
- 未增加依赖、联网、素材或数据库迁移；等级、金额与目标起点规则不变。

## 已执行检查

- Dart 格式化完成。
- flutter analyze：No issues found，日志 `.buildlog/corner-v13-analyze.log`。
- flutter test：136 项全部通过，日志 `.buildlog/corner-v13-tests.log`。
- 覆盖320×640、360×800、390×844、平板横竖屏和大字体；小猪触碰不改数据、等级编辑删除重算；无互动按钮、无设置入口；帮助到备份；心愿清除取消/确认及提交后读失败重试。
- 新帮助导航测试初次因懒加载列表未滚到入口及默认平板存在多个 Scrollable 而失败，修正为定位帮助列表滚动；未改变产品行为绕过问题。
- Android debug 测试入口构建成功，日志 `.buildlog/corner-v13-test-build.log`。
- 普通入口release构建成功（20.2MB），日志 `.buildlog/corner-v13-release.log`。`adb install -r`返回Success，已启动日常应用 `dev.wallehog.wallehog/.MainActivity`，未卸载或清空用户数据。设备参数复查与原值一致。

## 真机与截图

CGL-W00 / Android 16，独立 `.uitest` 沙盒运行 `integration_test/pig_room_test.dart`（含 records 和 growth）：3 项完成、0 失败、BUILD SUCCESSFUL。覆盖真实SQLite、备份往返、成长门槛及去重、触碰逐帧动作和不改数据；日志 `.buildlog/corner-v13-device.log`。系统无法读取测试logcat，以原生运行器结果为依据。

手机视口临时1080×2340、density=443，约390×845dp，锁竖屏；结束finally恢复原2032×3048、density=400、user_rotation=1、accelerometer_rotation=1。日常应用未参与测试。

实际Flutter截图已逐张目视检查：

- [直接展示小猪](screenshots/corner-v13-pig-room-empty.png)
- [触碰后的气泡](screenshots/corner-v13-pig-room-talk.png)
- [帮助进入备份](screenshots/corner-v13-ui-backup.png)

限制：平板模拟手机逻辑视口，非独立手机硬件；平板和大字体依赖widget回归，本轮未新增平板真机截图。未执行人工TalkBack和手指手感验收。无新角色素材；release仍使用开发签名。
