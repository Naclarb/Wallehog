# Phase 1 可靠性修复验收记录

日期：2026-10-25。依据用户批准的 REL01–REL04。本轮仅修复可靠性阻塞项，不宣布 Phase 1 完成。

## 根因与实现

1. 原 `writeCommitted` 仅描述一次操作，只有切换心愿会在提交后读取失败时取消 `loaded`。其他路径可关闭弹窗后继续使用过期心愿。现所有记录增删改、心愿创建/编辑/清除/切换和备份恢复共用 `_write`；独立 `needsRecovery` 保持到完整一致快照读取成功，期间 `loaded=false`，所有业务写入在调用仓储前被拒绝。失败重读、重读进行中及尝试其他写入均不能解锁。汇总、所有心愿、当前选择、记录与归属恢复后才开放写入。
2. 恢复只调用 `readSnapshot`，不重放事务。首页保留原重新读取入口；帮助页与备份页异常期间也可恢复。计算器、心愿弹窗订阅控制器，已提交后冻结输入且保存按钮变为重读。关闭弹窗不会绕过全局保护。正常页面构图、素材、轮播方向未变。
3. 原历史记录解码调用新输入构造器，设备日期回退会把合法历史记录判为未来日期。新增 `SavingRecord.fromStorage` 只跳过与今天的比较，保留日期格式/真实日历、金额、类型、身份及时间顺序校验。普通构造器仍校验新输入；仓储在事务内再次验证新增或更改的日期，编辑允许保留数据库原有日期。备份历史解码也不依赖今天；同 token 的已提交请求重放在日期回退后仍幂等。无日期改写、schema 升级或迁移。
4. 原非金额编辑将任意保存失败都变成只读退出流程。现未提交失败保留编辑内容并直接安全重试；已提交读取失败只允许重读，保留记录身份、client_token 和 Goal 归属。

补充写路径审查：SQLite 迁移仅在打开数据库时执行，失败不删库；原成长庆祝去重只写独立展示标记，不影响记录/金额/心愿快照，失败沿用普通反馈。新增前置 `canWrite` 检查，恢复期间不发起依赖旧快照的庆祝标记写入。文件导出不改业务数据库，恢复期间导出/选文件入口禁用。

## 先失败、后修复的证据

先新增 13 项回归并在旧代码执行：2 项通过、11 项失败。失败包括七类写入提交后仍 `loaded=true`、切换心愿恢复锁仍可被其他写入绕过、日期回退历史读取失败、未提交编辑无法直接重试，以及关闭心愿弹窗后录入仍可用。日志：`.buildlog/reliability-red.log`。随后实现修复，再增加真实 SQLite 事务中断断言；并非把旧测试改成跳过。

补充只读输入断言先失败（`.buildlog/reliability-readonly-red.log`），随后修复旧非金额编辑在提交后仍可改输入的问题。Android 测试为重复编辑显式等待原生键盘退场并定位记录文字；临时库清理在测试体的 `finally` 中完成，避免异步 teardown 等待平台回调。上述调整仅在测试代码，不改变产品导航或业务行为。

## 关键回归

| 测试 | 验证内容 |
| --- | --- |
| test/application/reliability_recovery_test.dart | 八类写入分别提交成功、快照失败；直接读取真实 SQLite 确认提交结果；恢复前、重读失败后、Completer 控制的重读进行中，拒绝所有业务写入且仓储调用次数不变；最终重读恢复全部记录、选择、所有心愿、金额、次数与归属；恢复后新记录只归当前心愿。 |
| 同文件：提交前失败与事务回滚 | 明确注入仓储调用前失败，编辑安全重试保留 ID/归属；同 token 重放不重复。真实 SQLite 触发器分别在记录已插入后、归属插入前，以及记录已删除后、归属删除前中止事务；断言整笔回滚，解除故障后重试成功。 |
| test/data/historical_date_test.dart | 注入本地日历，模拟同一时刻跨 UTC+8/UTC-7 日界及一年多日期回退；真实文件数据库关闭重开，备份解码/恢复，历史日期不变；仍可新增今天记录、编辑原日期、幂等重放；新增/更改为未来日期拒绝；SQLite 与备份中的错误格式/无效日历仍拒绝。未修改宿主机或设备系统时区/日期。 |
| test/widgets/reliability_recovery_test.dart | 非金额编辑未提交失败保留内容可重试，提交后读取失败仅重读且不增加写入次数；创建心愿已提交后关闭弹窗，Add 禁用，帮助页可失败重试再恢复，随后真实录入归属正确。 |
| test/support/fault_injecting_repository.dart | 事务委托前、委托成功返回后、快照阶段独立开关；记录尝试/提交次数；Completer 明确控制读取中状态。委托真实 SQLite，不把成功事务伪装成失败写入。 |
| integration_test/reliability_test.dart | 独立 Android .uitest 沙盒与专用临时库验证 UI 恢复入口、写锁、编辑重试、备份恢复后只重读，以及注入日期回退后 Android SQLite 重开。 |
| test/domain/backup_test.dart | 更新历史日期契约：不再用当前设备今天拒绝历史日期；仍拒绝重复 token、无效日历时间及其他备份损坏。 |

## 本轮修改文件

- 控制与数据：`lib/application/records_controller.dart`、`lib/data/sqlite_record_repository.dart`、`lib/domain/saving_record.dart`、`lib/domain/backup.dart`。
- 异常交互：`lib/features/entry/calculator_sheet.dart`、`lib/features/entry/entry_page.dart`、`lib/features/wishlist/goal_editor.dart`、`lib/features/home/home_page.dart`、`lib/features/home/goal_carousel.dart`、`lib/features/help/help_page.dart`、`lib/features/backup/backup_page.dart`、`lib/shared/recovery_notice.dart`。
- 测试：上表六个文件（包含新增 support 与 integration 文件）。
- 文档：`README.md`、`docs/PRODUCT_SPEC.md`、`docs/DESIGN.md`、`docs/ROADMAP.md`、`docs/VERIFICATION.md`、本文。

工作区此前已有大量未提交改动，本轮保留原工作，不混合提交、不暂存父项目、不推送。

## 最终验证

| 检查 | 结果 |
| --- | --- |
| 格式 | 最终检查 72 个 Dart 文件、0 改动；`.buildlog/reliability-format.log`。 |
| 静态分析 | 最终 No issues found；`.buildlog/reliability-analyze.log`。 |
| 完整自动化测试 | 189 项全部通过（原 175 项 + 14 项关键回归）；`.buildlog/reliability-tests.log`。 |
| 空白检查 | `git diff --check -- .` 退出码 0；`.buildlog/reliability-diff-check.log`。 |
| Android 独立测试包 | 最终构建成功；CGL-W00 / Android 16，390dp（1080×2340、density 443）OK (1 test)，16.072 秒；360dp（1080×2400、density 480）OK (1 test)，16 秒。日志：`.buildlog/reliability-device-390.log`、`reliability-device-360.log`。 |
| Android 普通 arm64 release | 最终构建成功，23.9 MB；`.buildlog/reliability-release.log`。版本沿用 0.5.0+5、现有开发签名。 |
| 普通应用覆盖更新与启动 | 用户解除系统 USB 安装限制后，`adb install -r` 返回 Success，普通包 `dev.wallehog.wallehog/.MainActivity` 冷启动 Status: ok，215ms；未卸载、清空数据或用测试包替代。日志：`.buildlog/reliability-install-release.log`、`reliability-launch-release.log`。 |
| 升级保留数据检查 | 同一 360dp 视口升级前后，普通应用 18 项可见文本/语义标签完全一致，差异 0；包含现有心愿、累计及可见记录。此为 UI 比对，不冒称已逐行读取普通应用全部私有数据库。原始 XML 与摘要位于 `.buildlog/reliability-before.xml`、`reliability-after.xml`、`reliability-data-comparison.log`。 |
| 设备参数恢复 | 已回读恢复为物理 2032×3048、density 400、user_rotation=1、accelerometer_rotation=1，无 size/density override；普通应用保留前台。 |

日志统一位于 `.buildlog/reliability-*.log`，不提交机器构建产物。

普通 APK：`build/app/outputs/flutter-apk/app-release.apk`（25,025,351 字节）。SHA-256：`4C43879160C2B8A90F12560086A53D8315F73CE3224DB33F9B6346B07804A3E3`。版本号沿用原值，以上哈希标识本轮最终构建。

## 限制与最终 Phase 1 入口

- 本轮不解决长列表性能、极端累计显示精度、外键迁移、专用 Git 仓库和发布签名等审查项；不改角色实验代码或轮播方向。
- 可控故障测试覆盖仓储调用前、SQLite 事务内回滚及提交后读取失败，不等价于真实断电、磁盘物理损坏或 Android 进程被杀的全组合测试。
- 真实跨时区采用注入本地日历，未擅自更改用户系统时间。连接设备是平板，须以手机逻辑视口验证，不能替代独立低端手机性能或人工 TalkBack 验收。
- 最终 Phase 1 验收仍应确认轮播方向、一般问题处置和可接受性能标准，完成冻结版本的手机验收及覆盖升级保留数据检查。
- REL01–REL04 可靠性阻塞项已修复并通过上述最终验证，具备进入最终 Phase 1 验收的条件；不宣称 Phase 1 完成。
