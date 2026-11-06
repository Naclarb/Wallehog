# 柔和极简交互 v2.0

日期：2026-10-24；对应 S01–S04，用户明确授权本轮交互与文字精简。

## 实现

- 心愿编辑由传统标题/说明/双列文字选项改为圆角柔色弹窗：一排四个物件、名称和金额、关闭/清除/保存图标。输入以浅粉灰填色代替硬描边，焦点仅保留低对比细线；保留输入上限、错误、失败重试及清除二次确认。SDK Icons 为现有图标字体，不引入网络字体或依赖。
- 记录移除三点菜单和轻触编辑。长按进入原记录计算器；旧非金额记录继续兼容原编辑页。向右拖动在半行处停留，显示垃圾桶，点击后弹出小型二次确认；全程滑动不会直接删除。左滑/点行收起，父列表只允许一条展开，稳定 ID 防止删除后状态串行；纵向手势仍交给首页滚动。
- 删除入口在收起状态不可点击、不向读屏暴露；提供编辑/删除的读屏自定义动作，删除动作依旧经过确认。控制器忙碌时禁用行操作，减少动画时跳过回弹动画。行高至少 52dp。
- 底部导航、心愿计数提示、空心愿操作、备注/日期入口、备份导出与恢复改用图标或精简表达；tooltip、读屏名称和必要状态保持。无备注记录仅展示日期和金额，省去重复的默认标题；有备注仍显示内容。
- 金额、日期、心愿名称、错误、破坏性确认、恢复预览及帮助正文继续使用文字，避免操作含义丢失。无数据库或依赖变化。

## 自动验证

- flutter test：163 项全部通过，见 .buildlog/soft20-tests.log。新增 6 项检查：半行停留/不自动删除/取消与确认后汇总一致；轻触不编辑/长按原记录并更新归属进度；小幅回弹/左滑收起/单行展开/删除失败保留；减少动画/纵向浏览不展开；360dp 下普通和双倍字体心愿编辑保存。现有手机、平板、SQLite、备份、反馈回归保留。
- flutter analyze：No issues found，见 soft20-analyze.log。
- dart format 已执行，见 soft20-format.log；修改代码 diff 空白检查通过。

## 设备与构建

- 普通 main.dart arm64 release 构建成功，23.9MB（.buildlog/soft20-release.log）。
- adb install -r 返回 Success（soft20-install.log）；普通包 dev.wallehog.wallehog/.MainActivity 启动 Status: ok（soft20-launch.log），无卸载、清库或日常记录修改。
- CGL-W00 平板临时模拟 390dp（1080×2340、density 443）及 360dp（1080×2400、density 480）手机视口；目视检查[首页](screenshots/soft20-home.png)、[心愿编辑](screenshots/soft20-editor.png)、[360dp 弹窗](screenshots/soft20-editor360.png)、[右滑半行](screenshots/soft20-swipe.png)、[删除确认](screenshots/soft20-confirm.png)、[长按编辑](screenshots/soft20-edit-record.png)。设备删除检查只取消确认，编辑检查只打开后退出，不保存修改。
- 原始 2032×3048、density 400、user_rotation=1、accelerometer_rotation=1 已恢复，普通应用保持前台。
- 限制：手机视口在平板模拟，未在独立手机硬件验收；未做人工 TalkBack 完整验收。

保留已有未提交工作；未暂存父项目、未提交混合改动、未推送。完整列表仍使用原内存快照，未测五万条极限性能。
