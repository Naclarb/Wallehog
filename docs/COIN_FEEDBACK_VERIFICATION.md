# 投币反馈 Phase 1 验证

日期：2026-10-23。范围：PRODUCT_SPEC.md G01–G05。

## 实现

- 保留首页布局、SQLite schema、金额计算和计算器提交逻辑。复用 pig-hero-v2.png，没有新增运行依赖。
- 新增成功且统一快照可读后显示金币飞向小猪（350ms）、小猪轻跳/缩放/旋转（300ms）和本地随机台词；约 2 秒自动消失。Goal 原生圆环过渡为 450ms，金额与历史先更新。
- 新反馈直接移除旧提示，不排队；录入入口另有并发弹窗保护，写入继续使用现有 busy/client_token 幂等机制。
- 减少动态效果时立即呈现静态猪、成功金额与台词，读屏 liveRegion；动画控制器 dispose 释放。
- 台词包含普通、接近目标、目标达成、回来四组。目标达成仅本次由未达成跨越目标触发。

## 已执行

- dart format：本次修改的 Dart 文件。
- flutter analyze：无问题。
- flutter test：完整业务/数据库/布局/反馈回归通过，最终数量见交付说明。
- flutter build apk --debug：成功，build/app/outputs/flutter-apk/app-debug.apk。
- 新增检查：+27 元真实计算器提交；Goal=2700 分；重复点击仅一笔；第二笔在反馈仍显示期间继续录入且只显示一个反馈；提示自动消失；飞行中卸载 widget 无异常；减少动画仍有成功文字；本地场景优先级。
- 原失败/提交后读取失败测试增加“没有奖励”断言；目标达成测试改为断言奖励组件，避免随机台词导致不稳定。

## 逐帧证据

390×844 Flutter widget 渲染截图，非真机录屏；保存后 300ms、400ms、650ms。前 200ms 左右包含原有 Bottom Sheet 退出过渡，截图时间从保存成功开始计。截图通过真实 HomePage/CalculatorSheet 和 MemoryRepository 生成；SQLite 行为由现有数据库回归验证，本轮未跑真机集成测试。

- [300ms 金币入猪](screenshots/deposit-300ms.png)
- [400ms 小猪弹跳](screenshots/deposit-400ms.png)
- [650ms 动作结束](screenshots/deposit-650ms.png)

复现：`flutter test test/widgets/coin_deposit_test.dart --update-goldens --dart-define=CAPTURE_FEEDBACK=true`。截图模式从 Windows 加载微软雅黑和应用 Nunito、MaterialIcons；不打包系统字体，个别装饰符可能使用测试字体占位。普通测试不依赖 Windows 字体，不比较随机台词的逐像素结果。

## 限制

未保存“最后打开”时间；不改数据库前提下，久别回来采用最近记录至少 7 天的代理条件，仅本次首页首次成功保存使用，不能精确识别仅打开但未记录的行为。没有新增持久化或每日催促。

Git 工作区已有大量未提交改动，保留全部既有工作；本轮未自动提交或推送。
