# 帮助录入与卡牌闪烁修复验收

日期：2026-10-24；对应 PRODUCT_SPEC.md DCK05–DCK06。

## 修复与原因

- 帮助页原先主动以空占位替代中央加号。手机底栏与平板侧栏现在统一保留记一笔；从帮助页直接录入后仍保留该页，记录计入当前心愿。
- 旧前后层的包装结构不同，预览晋升时会重建子树；GoalCard 的 active 状态还会切换容器与图片的 Key，导致图片重新解码展示、进度环状态重建。现在各层使用同一结构与心愿 ID Key，只调整绘制顺序及变换；活动标识放在独立定位标记，保持图片和进度环子树身份。
- 提前缓存四种内置物件，避免反向切换首次遇到未预览物件时临时解码。增加 RepaintBoundary；保留循环、减少动画、切换期间禁止录入、失败回退。无新运行依赖、领域规则或数据库迁移。

## 自动验证

- dart format 与 diff 空白检查通过；flutter analyze 通过。
- flutter test：170 项通过（.buildlog/deck-fix-tests.log）。新增手机/平板帮助页保存与归属、两方向换层及结束时图片 Element / 进度环 State 身份保留、真实上下拖动与写入失败回退。已有手机大字体、平板、SQLite、备份与金额回归保留。
- 普通 arm64 release 构建通过，23.9MB（.buildlog/deck-fix-release.log）。

## 设备

- 用户在系统安装界面完成确认后，adb install -r 返回 Success；普通包 dev.wallehog.wallehog/.MainActivity 启动 Status: ok。未卸载或清数据，未新增、修改或删除用户记录。
- CGL-W00 临时模拟手机 1080×2340 / 443dpi，检查帮助页中央加号以及从帮助页打开的完整计算器：[帮助](screenshots/deck-fix-help.png)、[直接录入](screenshots/deck-fix-help-calculator.png)。
- [实际滑动录屏](recordings/deck-fix.mp4)及首段 15fps 抽帧检查：切换时图片与圆环保持可见，未观察到空白闪帧。原先选中心愿已切回。
- 2032×3048、400dpi、user_rotation=1、accelerometer_rotation=1 已恢复；普通应用保持前台。
- 限制：手机尺寸在平板模拟；抽帧检查不是完整帧耗时性能测量，未做完整人工 TalkBack 验收。

保留已有未提交工作，未暂存父级文件、未提交混合历史改动、未推送。临时视频抽帧工具只安装于被忽略的 .buildlog/media-tools，不是应用依赖。
