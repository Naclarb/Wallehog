# 小猪屋 v1 验证

日期：2026-10-23。范围：PRODUCT_SPEC.md PR01–PR05。

## 已实现

- 独立标题、欢迎语、柔粉场景、现有 pig-hero-v2.png、上方本地气泡、下方五级成长与进度，摸摸和听它说话两个入口。
- 点猪或摸摸触发 360ms、最高 10dp 的轻跳和随机本地鼓励语；听它说话仅换本地台词。不调用控制器写入，不增加记录或经验，尊重减少动态效果。
- 复用 PigGrowth 与统一快照，门槛为 0/5/15/30/60；有效零金额历史记录继续按原规则计次，Saved Money 和 SQLite 均未修改。
- 手机底栏、宽屏侧栏保留首页、小猪屋、历史和 Add；历史改为嵌入导航容器，Add 在三个主要页面直接打开原计算器。系统返回从次级页回首页。
- 无新依赖、角色素材或数据库迁移，无额外游戏玩法。设置中的现有成长面板仍保留。

## 实际执行结果

- Dart 格式化完成。
- flutter analyze：No issues found。
- flutter test：135 项全部通过，日志 `.buildlog/pig-room-tests.log`。
- flutter build apk --debug：成功，输出 `build/app/outputs/flutter-apk/app-debug.apk`。
- 新增 widget 覆盖 320×640、360×800、390×844、813×1219、1219×813；验证无记录 Lv.1、即时位移、本地台词、摸摸不改金额/次数、第五条升级、编辑金额不变级、删除降级、控制器重建后重算、两倍字号及两个次级页 Add。
- 既有纯 Dart 门槛、SQLite 编辑删除/关闭重开、备份恢复和业务回归测试全部通过。既有锁定首页测试随新嵌入式历史导航改为点击首页返回。

## 限制

初次实现只进行了 widget 测试，后续真机结果见下节。保留工作区既有改动，未提交或推送父仓库文件。

## 真机验收补充（2026-10-23）

设备：USB 连接的 CGL-W00 / Android 16。使用独立 `dev.wallehog.wallehog.uitest` 与 `.uitest.test` 包，未覆盖、卸载或清空日常应用。测试数据库单独命名，完成后清理。

先验证手机视口：设备临时设置 1080×2340、density=443，约 390×845dp，锁定竖屏；原值为 2032×3048、density=400、user_rotation=1、accelerometer_rotation=1，手机测试结束通过 finally 恢复。截图由真机 Flutter RepaintBoundary 导出，1.5 倍像素；不是桌面 mock。

手机原生运行器：`OK (3 tests)`，耗时 91.455 秒。入口 `integration_test/pig_room_test.dart` 同时运行原有记录与成长真机测试。

- 新增小猪屋测试验证空数据 Lv.1、触摸逐帧弹跳、台词属于本地库、摸摸/聊天后真实数据库仍无记录；首页、小猪屋和历史的 Add 均直接录入成功。
- 从小猪屋新增第五笔后立即 Lv.2；历史 UI 编辑金额不加次数，删除后退至 Lv.1。
- 关闭并重新打开真实 SQLite、销毁并重建控制器/UI，4 次仍为 Lv.1；验证 5/14/15/29/30/59/60 次的实际页面等级，60 次为 Lv.5 满进度。
- 原有记录/目标、备份往返、五级门槛及升级去重真机用例通过；本地静态分析及 135 项回归再次全部通过。
- 初期固定 90ms 取样未捕捉到实时设备动画，改用逐帧采样；随后修复采样回调使用 guarded 查询 API 导致的测试框架冲突。产品代码未因此修改，最终逐帧位移断言通过。设备 logcat 无可读 Flutter 日志，测试补充了沙盒错误日志，最终成功轮无错误文件。

手机截图已目视检查，标题、气泡、现有角色、进度、互动按钮及固定底栏均完整显示：

- [空记录 Lv.1](screenshots/pig-room-phone-empty.png)
- [本地对话](screenshots/pig-room-phone-talk.png)
- [新增后 Lv.2](screenshots/pig-room-phone-lv2.png)
- [满级 Lv.5](screenshots/pig-room-phone-lv5.png)

日志：`.buildlog/pig-room-phone-instrument.log`（最终通过结果）、`.buildlog/pig-room-device-analyze.log`、`.buildlog/pig-room-device-regression.log`。早期 Gradle 测试日志保留用于失败诊断，以最终原生运行器结果为准。

恢复原始设备设置后，平板横屏约 1219×813dp 再跑相同完整入口：`OK (3 tests)`，耗时 92.986 秒；日志 `.buildlog/pig-room-tablet-instrument.log`。平板真实截图已导出并目视检查，侧栏、完整场景、等级与按钮均无裁切：

- [平板空状态](screenshots/pig-room-tablet-empty.png)
- [平板本地对话](screenshots/pig-room-tablet-talk.png)
- [平板 Lv.2](screenshots/pig-room-tablet-lv2.png)
- [平板 Lv.5](screenshots/pig-room-tablet-lv5.png)

两轮最终测试均通过，共 6 次真机用例执行。结束后确认 `wm size=2032×3048`、`density=400`、`user_rotation=1`、`accelerometer_rotation=1`，没有残留尺寸覆盖。测试包保留在设备，日常应用未修改。测试后重新执行普通入口 `flutter build apk --debug` 成功，`build/app/outputs/flutter-apk/app-debug.apk` 为普通应用，非测试入口；日志 `.buildlog/pig-room-normal-build.log`。

限制：使用真实平板模拟手机逻辑视口，并非独立手机硬件；互动由真机自动化触发、截图由开发者目视检查，未进行用户手指手感或 TalkBack 人工验收。“重开”验证 SQLite/控制器/UI 重建，不包含系统杀进程或整机重启。
