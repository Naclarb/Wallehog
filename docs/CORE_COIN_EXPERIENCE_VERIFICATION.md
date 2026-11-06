# 核心投币体验 v1 验证

日期：2026-10-25。需求 CD01–CD04；已阅读 INTENT、PRODUCT_SPEC、DESIGN、ROADMAP 及 GAMIFICATION_AND_ANIMATION。保留现有首页、3D 猪和 PS5 图像，无新增功能、应用依赖或数据库迁移。

## 检查现有实现的结论

- SQLite.save 在事务中插入记录与当前心愿归属，client_token 唯一；重复请求校验后直接返回。编辑保留 ID、创建时间和归属。删除在事务中移除记录与关联。
- RecordsController._perform 使用 busy 串行写入；提交后 readSnapshot 在同一读取事务获得记录与心愿，再统一发布。提交后读取失败仅重读，不重新插入。计算器另有 _saving 防重复点击和 _committed 重试状态。
- SavingsSummary 使用整数分及溢出校验累加 savedMinor；每条有效记录 Good Choices 加一，包含兼容旧非金额记录；金额大小不影响次数。
- Goal.progressMinor 按 recordIds 归属汇总；progressFraction 展示封顶到 1。编辑删除通过同一快照重算，无新业务状态。
- 首页 InlinePig 容器 84×78dp，原图 Image 80×62dp、contain，方形素材实际绘制 62×62dp。此前成功层又复制一只猪，金币只飞向该复制猪；顶部猪还提前轻跳，已改正。

## 动画实现

HomePage 持有 1400ms AnimationController，金币层与首页原猪订阅同一时间轴。前 550ms 渐变金色硬币沿带缓入缓出的弧线进入投币口，末段缩小消失；之后 160ms 轻压缩，690ms 轻跳并恢复。本地随机鼓励语从入槽后淡入，提示 2300ms 后清除。

原图投币口中心为归一化坐标 (.55,.15)。每帧读取图片 RenderBox，以 BoxFit.contain 计算实际图片矩形，再经 localToGlobal/globalToLocal 转到反馈层。屏幕、安全区、侧栏、滚动及组件留白均计入，未写死屏幕落点。弧高经 Android 关键帧检查调整，避免金币擦过状态栏。保存前若已滚出页头，成功后确保原猪可见。

计算器等实际路由退场完成才返回成功，金币不藏在关闭中的遮罩后。累计金额沿用 700ms Tween，Goal 沿用原进度 Tween，真实值始终来自同一控制器快照。成功层 IgnorePointer，不阻塞 Add、导航或记录操作。新 Add、编辑删除、切心愿/页面及后台取消旧层与旧异步事件，不排队。退出释放两个主页控制器、提示计时器及组件资源。

减少动态效果：无金币、位移或形变，真实数字和本地成功文案直接呈现；播放中启用也立即收敛。现有猪图以整体原生形变回应，不宣称完成专项文档中尚待资产制作的耳朵/眼神/嘴部表演或音效。

## 实际验证

| 项目 | 结果与证据 |
| --- | --- |
| 保存 ¥2、¥200、再 ¥2 | Widget 三尺寸连存及 Android SQLite 流程；总额/Goal = 20400 分，Good Choices = 3；大小金额同等单次计数 |
| 重复点击、动画未完再次 Add | Widget 双击保存仍每笔只写一次；上一笔 560ms 时立即继续录入，无动画排队、错误累计 |
| 模拟写入失败 | MemoryRepository 注入仓储写异常：输入保留、无成功层或金币；解除异常重试只新增一笔 |
| 提交成功后读取失败 | 既有用例通过：已提交一笔，界面仅允许重读，无重复写入；成功重读后正常反馈 |
| 修改、删除 | 长按编辑与右滑确认删除用例通过；金额/原 Goal 重算，次数为 2/1；明确断言无 depositFeedback 或 depositCoin |
| 不同屏幕落点 | 360×800、390×844、900×700：飞行 500ms 时金币距原图投币口小于 8dp，550ms 后消失；Android 手机视口录屏关键帧人工检查 |
| 减少动态效果、资源释放 | 保存前/播放中开启、飞行中销毁、重复创建页面等通过；无金币、无提前弹跳、无 ticker 异常 |
| Flutter analyze | No issues found；.buildlog/core-coin-analyze.log |
| flutter test | 175 项全部通过；.buildlog/core-coin-tests.log |
| 格式与空白 | dart format；指定改动范围 git diff --check |
| Android release | arm64 普通应用构建成功，23.9MB；.buildlog/core-coin-release.log |

故障注入在仓储边界进行，不通过破坏用户数据库模拟磁盘故障。真实 SQLite 测试在 .uitest 独立沙盒及每次新建的测试数据库中运行，未向普通应用添加验收记录。

## 修改文件清单

- 应用：lib/features/home/home_page.dart、lib/features/entry/calculator_sheet.dart、lib/shared/coin_deposit_feedback.dart、lib/shared/inline_pig.dart、lib/shared/pig_character.dart。
- 测试：test/widgets/core_coin_experience_test.dart（新增）、test/widgets/coin_deposit_test.dart、test/widgets/home_refinement_test.dart、test/widgets/soft_interactions_test.dart、integration_test/core_coin_experience_test.dart（新增）。
- 文档：README.md、docs/PRODUCT_SPEC.md、docs/DESIGN.md、docs/ROADMAP.md、docs/GAMIFICATION_AND_ANIMATION.md、本文。
- 交付证据：docs/recordings/core-coin-experience-v1.mp4。

工作区此前已有大量未提交工作；上述清单仅为本轮触及文件，原有改动保留，未创建混合提交或推送父仓库。

## 限制

连接设备是 CGL-W00 / Android 16 平板，以手机逻辑视口验证；不能代替独立低性能手机的 profile 性能、帧耗时或人工 TalkBack 验收。动画采用单个金币和局部 Transform，无循环待机、粒子或解码新角色帧，但尚未测得低端机 p95/p99、50 次中断后的峰值内存。release 沿用项目现有开发签名。

## Android 证据与普通安装状态

- 最终代码 390dp（1080×2340、density 443）JUnit：OK (1 test)，18.310 秒；360dp（1080×2400、density 480）：OK (1 test)，18.161 秒。日志分别为 .buildlog/core-coin-device-390.log、core-coin-device-360.log。
- [真实 Android 全流程录屏](recordings/core-coin-experience-v1.mp4)：约 14.1 秒，1080×2340，展示 Add → 逐键输入 ¥2 → 保存/投币/回应，再保存 ¥200、¥2，总额与 Goal 最终 ¥204 / ¥400、51%。为独立 .uitest 包及独立测试数据，非普通应用用户记录。只裁除录屏前后桌面/测试运行器画面并压缩，无变速、拼接、合成动画或后期配音。以 100ms 间隔人工检查入槽与猪回应关键帧（.buildlog/core-coin-impact.png）。录屏为 debug，不能用来替代 release 性能测量。
- 普通包执行 adb install -r，系统确认完成后返回 Success；普通包 dev.wallehog.wallehog/.MainActivity 冷启动 Status: ok（215ms）。首页可读取原有累计 ¥1532.00、两个心愿及现有记录；未卸载、未清数据、未在普通应用添加测试记录。日志：.buildlog/core-coin-install-release.log、core-coin-launch-release.log。
- 原始设备参数已记录：2032×3048、density 400、user_rotation=1、accelerometer_rotation=1。已执行 wm size/density reset 并恢复旋转 1/1，回读确认为原始物理尺寸/密度，无 override。普通应用保留在前台。
