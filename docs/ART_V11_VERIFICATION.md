# 美术精修 v1.1

日期：2026-10-23。授权：用户要求吸收概念图美术，推进现代、轻量、精简的省钱习惯体验。规格编号 A01–A05。

## 设计结果

- 心愿：径向柔粉光晕、白色真实进度弧、原创透明立体礼物；“已积累”百分比强调向目标靠近。通用礼物不冒充用户的具体物品。
- 累计：大金额保留，用“每一点，都算数”连接积极记录；保留自行记录、非真实存款的说明。
- 最近记录：去掉嵌套卡片，使用轻量分隔行，保留正数金额、三条预览和编辑入口。
- 导航：手机“记一笔”以粉色胶囊强调，所有页面仍直接打开计算器；平板入口同名。
- 计算器：“这次省下多少？”和“记录这笔节省”，避免把记录表达为真实存款操作。
- 小猪屋：同一柔粉光晕，无中英文重复标题，保留原角色、互动和成长。
- 未增加登录、支出列表、联网、依赖、数据表或强制输入。未修改金额解析、目标边界和成长规则。

## 素材

`assets/characters/wish-gift-v1.png` 由内置 image_gen 生成，透明背景，完整提示和来源在同目录 README.md；概念图仅作为审美参考，未复制或打包。

## 本轮实际验证

- `dart format --output=none --set-exit-if-changed lib test integration_test`：50 个文件，0 个待格式化。
- `flutter analyze`：No issues found。日志 `.buildlog/art-v11-final-analyze.log`。
- `flutter test`：135 项全部通过。日志 `.buildlog/art-v11-tests.log`。首次回归发现一处旧文案断言，更新为“再积累”后全量通过；未删减行为覆盖。
- 手机布局覆盖 360×800、390×844；既有平板、窄屏、大字体、导航及快速录入回归通过。
- 测试入口 Android debug 构建成功，日志 `.buildlog/art-v11-test-build.log`。
- 普通入口 `flutter build apk --release --target-platform android-arm64` 成功，20.2 MB，输出 `build/app/outputs/flutter-apk/app-release.apk`，日志 `.buildlog/art-v11-release.log`。未安装覆盖日常应用。

## 真机验证与截图

CGL-W00 / Android 16，以独立 `.uitest` 应用运行 `integration_test/records_test.dart`；Gradle 报告 1/1 完成、0 失败、BUILD SUCCESSFUL。覆盖新增、精确算式、目标刷新、编辑删除、SQLite 重开、目标新起点及备份往返。设备限制导致无法取得 logcat，以运行器结果为依据。日志 `.buildlog/art-v11-device.log`。

临时手机视口：1080×2340、density=443，约 390×845dp，锁定竖屏；测试结束 finally 恢复原 2032×3048、density=400、user_rotation=1、accelerometer_rotation=1。日常应用未覆盖，未删除用户数据库。

截图由真实 Flutter RepaintBoundary 导出，已逐张目视检查，非概念 mock：

- [首页](screenshots/art-v11-ui-home.png)：心愿物件、真实百分比、累计金额、正数记录和主入口完整。
- [计算器](screenshots/art-v11-ui-calculator.png)：表达式、正数结果、可选项与确认按钮完整。
- [无心愿](screenshots/art-v11-ui-no-goal.png)：小猪、可选创建提示、累计与直接录入入口完整。

限制：真机为平板模拟手机逻辑视口，并非独立手机硬件；360×800、平板及大字体由 widget 回归覆盖，本轮未重新导出平板和小猪屋真机截图。未执行人工 TalkBack 或手指手感验收。构建继续采用既有开发签名，不用于商店发布。
