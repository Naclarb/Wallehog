# 小猪成长 Phase 2 验证

日期：2026-10-23。依据 PRODUCT_SPEC.md P01–P06 与用户“同等级不需要再次庆祝”的确认。

## 实现结果

- 等级从当前有效 Good Choices 推导：0–4 / 5–14 / 15–29 / 30–59 / ≥60；金额不参与成长。有效的历史零金额选择继续兼容。
- 等级和本级成长进度位于奖励提示与现有“小猪的角落”，没有新增首页主卡。满级显示满级文案，不产生每日任务。
- 五级独立角色素材映射接口，当前统一复用 pig-hero-v2.png，不生成新角色。
- 首次新增跨级显示短暂星光和轻微放大弹跳；正常记录只有投币反馈。编辑删除和恢复只重新计算等级，不播放负面或升级反馈。
- SQLite schema v3 仅新增等级庆祝去重表，等级仍不存储，不存在独立经验。v1/v2 升级有事务和回归覆盖；原记录、目标及历史 ID 高水位保留。
- 每个等级原子去重，删除后再升、重建、重读、关闭重开不重播；标记存储错误只降为普通成功反馈。减少动画时显示静态等级/星光和成功文字；控制器正常释放。

## 本地验证

| 检查 | 结果 |
| --- | --- |
| dart format | 本轮 Dart 文件已格式化 |
| flutter analyze | 无问题 |
| flutter test | 130 项全部通过 |
| Android release arm64 | 构建成功，18.9 MB；build/app/outputs/flutter-apk/app-release.apk |
| Android 测试构建 | assembleDebug + assembleAndroidTest 成功，target=integration_test/growth_test.dart，独立 .uitest 包名 |

新增测试覆盖所有等级上下边界、本级进度、满级、金额独立性、编辑不加次数、删除降级、真实 SQLite 重开、同等级再次跨越不重播、并发领取去重、v2→v3 保留记录/目标/ID、减少动画和动画中退出。既有 v1 迁移、金额计算、备份和手机/平板布局测试继续通过。

## 真机测试结果

用户允许 USB 安装并重新连接后，独立测试主包与 androidTest 包均安装成功。CGL-W00 / Android 16 / API 36 / arm64 平板，Android 原生 instrumentation 最终返回：

```text
dev.wallehog.wallehog.MainActivityTest:..
Time: 115.325
OK (2 tests)
```

- 原有集成流程通过：真实 SQLite 快速记录 +27、算式、Goal、编辑删除、数据库关闭重开、备份恢复与预览。
- 成长集成流程通过：5/15/30/60 四个门槛均由真实计算器新增 +27 触发首次升级；普通预置写入及重建不播放升级。
- 编辑单笔金额到上限不改变 Good Choices/等级；删除第 60 条后回到 Lv.4。
- 关闭数据库、销毁控制器和页面后重新打开，仍为 59 次/Lv.4；再通过计算器新增至 60 次时显示 Lv.5 普通奖励，不重复庆祝。
- 满级详情显示 60 次、Lv.5、完整进度和满级文案，无溢出异常。
- 此处“重启恢复”验证为真实数据库关闭重开与 UI/控制器重建，未模拟系统杀进程和设备重启。无障碍减少动画、手机尺寸和大字体由本地 widget 测试覆盖。

测试入口：integration_test/growth_test.dart（包含 records_test.dart）。仅访问独立 .uitest 沙盒中的 integration 数据库；测试后数据库已清理，日常应用未更新、卸载或清空。测试包保留在设备，可与日常应用区分包名。

日志：.buildlog/growth-device-build.log、.buildlog/growth-device-test.log。最初安装权限拒绝已解决，以本次明确 OK 结果为准。

## 真机截图

真实设备 Flutter RepaintBoundary 导出，1.5 倍像素，1829×1220；未修改系统分辨率/密度/旋转。已目视检查首次升级与满级详情，首页 Goal、Saved Money 与侧栏保持原层级。

- [Lv.2 首次升级](screenshots/growth-upgrade-lv2.png)
- [Lv.3 首次升级](screenshots/growth-upgrade-lv3.png)
- [Lv.4 首次升级](screenshots/growth-upgrade-lv4.png)
- [Lv.5 首次升级](screenshots/growth-upgrade-lv5.png)
- [再次升到 Lv.5，不重复庆祝](screenshots/growth-repeat-no-celebration.png)
- [小猪的角落：满级详情](screenshots/growth-corner-lv5.png)

## 数据与交付限制

庆祝标记限于当前本地数据库，删除记录和恢复 JSON 备份不会清掉；JSON v1 不传输展示标记。清除应用数据/卸载后无法保持展示历史。没有联网或新增运行依赖。

工作区保留已有未提交改动；没有提交、推送、卸载日常应用或清除其数据库。测试包使用 dev.wallehog.wallehog.uitest，与日常包隔离。
