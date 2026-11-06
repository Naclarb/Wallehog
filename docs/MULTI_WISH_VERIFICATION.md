# 多心愿与首页小猪 v1.5

日期：2026-10-24。需求 W01–W06；用户确认采用当前卡片接收新记录。

## 本次实现

- 心愿区改为横向层叠卡片，露出相邻卡与背后卡层，提供前后切换按钮、当前序号和添加入口；选中项持久化。
- 内置自由心愿、PS5 游戏机、耳机、相机；名称与目标金额可编辑，金额不预填。PS5 采用白色手柄、柔粉背景、白色真实进度环；耳机暖杏、相机浅紫。素材由内置 image_gen 生成并保存透明 alpha，来源和提示见 assets/characters/README.md。
- 每笔记录只归属保存时选中的心愿；累计只计算一次。编辑记录保持归属，删除重算；新心愿从零开始。清除一个心愿保留记录，不转移给其他心愿。
- schema v4 事务迁移保留旧目标边界及进度、记录与高水位、成长去重。备份 v2 保存所有心愿与唯一归属，并兼容 v1。
- 小猪直接展示在首页右上角，可见高度约 56dp，无按钮背景和独立角落弹层；轻触原地轻跳、短暂气泡，显示简短等级。不写库、不增经验，尊重减少动画。
- 心愿切换已提交但快照读取失败时暂停录入，重读成功后再允许保存，避免当前卡片与实际归属不一致。

## 已验证

- 格式化完成，静态分析无问题（`.buildlog/multi-analyze-final.log`）。
- 全套原有及新 SQLite/widget 回归 141 项通过（`.buildlog/multi-tests-final.log`）；随后新增 2 项纯 Dart 归属与恶意备份校验通过（`.buildlog/multi-domain.log`），以及 1 项心愿切换提交后读失败保护通过（`.buildlog/multi-selection-failure.log`），合计 144 项。样式选择区收紧为双列网格后，相关 20 项交互回归再次通过（`.buildlog/multi-picker-grid.log`）。
- 含 v1/v2/v3→v4、旧心愿进度、唯一归属、编辑删除、重启、备份往返、重复归属拒绝、v1 备份兼容；手机 360/390dp、320dp 互动、大字体、平板横竖屏、窗口缩放回归。
- Android 集成测试入口 debug 构建成功（`.buildlog/multi-test-build.log`）。

## 设备与交付

连接设备 CGL-W00 / Android 16。原始参数 2032×3048、density=400、user_rotation=1、accelerometer_rotation=1；手机验收临时 1080×2340、density=443，finally 恢复原参数。测试仅使用 `.uitest` 独立沙盒。

390dp 原生运行器完成 2 项、0 失败、0 跳过，Gradle BUILD SUCCESSFUL（`.buildlog/multi-device2.log`）；360×800dp 使用原生 am instrument 完成 `OK (2 tests)`，37.757 秒（`.buildlog/multi-device-360.log`）。覆盖快速记录、编辑删除、SQLite 重开、备份、多心愿滑动及新记录唯一归属、小猪原地触碰。

首次设备运行中旧截图辅助函数匹配到纵向和横向两个 Scrollable；已将复位目标限定为外层纵向滚动，再次验证通过。一次普通构建遇到测试与发布生成的插件注册文件冲突，改为完整串行构建重新生成；未修改注册文件绕过错误。

最终双列布局再次完成 390dp 真机 2 项通过、0 失败（`.buildlog/multi-final-device.log`），已目视检查所有实际 Flutter 截图：

- [PS5 与层叠心愿](screenshots/multi-ps5.png)
- [耳机](screenshots/multi-headphones.png)、[相机](screenshots/multi-camera.png)
- [双列样式选择](screenshots/multi-styles.png)、[首页小猪原地回应](screenshots/multi-pig.png)
- [360dp 首页](screenshots/multi-360-ps5.png)（卡片与小猪同最终实现，样式选择早期单列截图不作为最终样式验收）

截图内 70% 等数字来自独立测试记录，不是用户数据或模板预设金额。

普通 `lib/main.dart` arm64 release 构建成功，23.9MB（`.buildlog/multi-final-release.log`）；`adb install -r` 返回 `Success`，启动 `dev.wallehog.wallehog/.MainActivity` 返回 `Status: ok`、`LaunchState: COLD`，前台 Activity 复查为普通应用。未卸载或清空数据。安装后复查尺寸 2032×3048、density=400、两项旋转设置为 1，均恢复原值。

交付前进一步清理 Flutter 构建缓存，重新完整构建普通 release，57.9 秒成功（`.buildlog/multi-clean-release.log`），再次覆盖安装 `Success`、普通入口冷启动成功。已目视确认日常应用可读取原有金额与进度并展示多心愿入口；现有 PS5 曾通过编辑器切换到手柄样式，未修改金额或记录。最终静态分析无问题（`.buildlog/multi-final-analyze.log`）。

## 限制

手机体验使用平板临时手机逻辑视口近似，不等同独立手机硬件；未进行人工 TalkBack 验收。release 使用既有开发签名。PS5 手柄为生成的风格示意，非官方商品图；没有联网商品目录、价格建议或真实资金分配。

保留既有未提交工作；未提交或推送父仓库。
