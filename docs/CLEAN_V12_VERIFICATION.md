# 界面减字 v1.2 验证

2026-10-23，需求 C01–C05。用户授权移除冗余指导文字、将 Add 移出导航并在首页提供圆形加号，必要说明集中到帮助。

## 实现

- 手机和平板统一导航顺序：首页、小猪屋、历史、帮助。只有首页显示圆形浮动 ＋，保留底部滚动空间，直接打开原计算器。
- 计算器去掉标题、输入示例、空输入指导和底部资金说明；空态显示 ¥0.00，正常保存使用 ✓，保留关闭和“备注 · 日期”。图标与算式保留语义标签。
- 输入校验、失败信息、已提交后的重读和旧记录转换提示继续显示；删除、清除与恢复的确认继续在现场显示。
- 首页去掉口号、重复差额和常驻说明；保留心愿名称、实际进度、目标金额、累计节省及最近记录。小猪屋、设置和成长面板去掉重复静态解释。
- HelpPage 集中说明记录、算式、心愿起点、金额含义、编辑删除、成长和本地备份；无需联网，不写数据。
- 未增加依赖或数据库迁移，未改金额解析、目标边界、成长或幂等规则。

## 检查

- 格式化完成，flutter analyze：No issues found。
- flutter test：135 项全部通过。既有测试按新入口更新；覆盖手机两尺寸、平板、窄屏、小猪互动、帮助双倍字体滚动、仅首页显示加号、计算器确认和失败重读。
- 日志：`.buildlog/clean-v12-analyze.log`、`.buildlog/clean-v12-tests.log`。
- 测试入口 Android debug 构建成功，日志 `.buildlog/clean-v12-test-build.log`。
- 普通入口 release 构建成功（20.2 MB），日志 `.buildlog/clean-v12-release.log`；`adb install -r` 返回 Success，已启动 `dev.wallehog.wallehog/.MainActivity`，覆盖升级保留日常数据与设置。未卸载或清空日常应用。
- 390dp 手机视口真机流程：1/1 通过，0 失败，BUILD SUCCESSFUL。验证首页加号、帮助导航、计算器新增、编辑删除、目标及 SQLite 重开、备份往返。日志 `.buildlog/clean-v12-device.log`。

## 截图和设备

USB CGL-W00 / Android 16，以独立 `.uitest` 包运行，日常应用数据未参与测试。临时设置1080×2340、density=443，约390×845dp；原值2032×3048、density=400、user_rotation=1、accelerometer_rotation=1，finally 恢复。

初轮截图为实际 Flutter 渲染，已目视检查首页、计算器、帮助无裁切；初轮之后仅调整手机/平板导航为统一顺序。

- [初轮首页](screenshots/clean-v12-ui-home.png)
- [初轮计算器](screenshots/clean-v12-ui-calculator.png)
- [初轮帮助](screenshots/clean-v12-ui-help.png)

最终导航顺序在360×800手机视口重新跑同一完整入口：1/1通过、0失败、BUILD SUCCESSFUL；日志 `.buildlog/clean-v12-device360.log`。临时1080×2400、density=480，结束恢复上述原值。最终截图已目视检查，内容与加号互不遮挡，计算器键盘及确认按钮完整：

- [最终首页](screenshots/clean-v12-360-ui-home.png)
- [最终计算器](screenshots/clean-v12-360-ui-calculator.png)
- [最终帮助](screenshots/clean-v12-360-ui-help.png)

限制：平板模拟手机逻辑视口，非独立手机硬件；未做人工 TalkBack 和触感验收。系统无法获取测试 logcat，以原生运行器结果为依据。继续使用开发签名，非商店发布签名。
