# 轻量游戏化回应 v1.8

日期：2026-10-24；对应 J01–J04。保持首页布局、配色、字体、手柄/圆环与原猪素材，不增加任务、签到、虚拟币或照料要求。

## 实现

- 普通投币按新增记录 ID 奇偶轻微改变小猪侧倾方向；普通跳幅 7dp，里程碑 10dp。900ms 投币节奏保持原样。
- 首次记录、心愿过半、达成提供专属文字，里程碑在入币后短暂显示局部原生爱心/光芒。只出现一个反馈，优先级为达成、过半、首次、普通，不叠加弹窗。
- 首次为新增 ID=1；过半使用整数分的两倍进度比较，避免奇数目标和百分比四舍五入造成提前庆祝。仅比较保存前后同一目标，新增差集必须恰好一笔。
- 随机鼓励语排除上一句，避免相邻重复。编辑、删除、恢复、重开和页面重建不触发成功事件；过半/完成允许删除回退后未来新增重新跨越时回应，没有永久里程碑状态表。
- 反馈继续可穿透点击、再次 Add 立即收起，减少动画时呈现静态成功文字、无金币/侧倾/里程碑光芒。沿用原成长及去重，不改变金额、目标归属、SQLite 或备份，无新运行依赖。

## 实际验证

- 先添加规则测试并观察未实现失败（`.buildlog/warm18-rules-red.log`），随后规则、widget 与全套回归共 156 项通过（`warm18-tests.log`）。新增覆盖首次判定、奇数分目标、一次跨多个门槛、已达成后继续记录、不重复台词、三种反馈/减少动画及重建不重播。
- 格式检查 62 个文件无变化（`warm18-format.log`）；flutter analyze 无问题（`warm18-analyze.log`）。
- Android 原生运行器：390dp `OK (1 test)`，26.872 秒；360dp `OK (1 test)`，25.948 秒（`warm18-device.log`、`warm18-device-360.log`）。真实 SQLite 测试数据库位于 `.uitest` 沙盒，日常数据不参与录屏。
- [实际 Android 录屏](recordings/warm-feedback-android.mp4)：约 23.5 秒、1080×2340，连续展示首次 27、再记 23 达到 50%、再记 50 达成 100%，并回归三张心愿切换。目标 100 为独立测试输入，不代表 PS5 商品价格。仅裁去前后桌面，无变速、拼接或合成动画。
- 已目视检查录屏及[过半](screenshots/warm18-halfway.png)、[达成](screenshots/warm18-completed.png)截图，金额/百分比一致，反馈层保留 Add 操作空间。
- 普通 main.dart arm64 release 构建通过，23.9MB（`warm18-release.log`）。`adb install -r` 返回 Success；普通包 `dev.wallehog.wallehog/.MainActivity` 启动 Status: ok（`warm18-install-release.log`、`warm18-launch-release.log`）。未卸载或清空数据。

## 设备与限制

CGL-W00 / Android 16 平板临时模拟 390dp（1080×2340 / density=443）、360dp（1080×2400 / density=480）手机视口，不是独立手机硬件。原始 2032×3048、density=400、user_rotation=1、accelerometer_rotation=1 已恢复，前台为普通应用。

release 沿用开发签名；无人工 TalkBack 验收。保留现有未提交工作，未暂存或推送父仓库。
