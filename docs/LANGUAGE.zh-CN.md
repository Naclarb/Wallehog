# 界面语言

[English](LANGUAGE.md) · [简体中文](LANGUAGE.zh-CN.md)

更新：2026-11-06。

帮助 → 语言提供 **简体中文** 和 **English**。默认简体中文。选择保存成功后立即生效，保留在帮助页，重启后仍记住选择。偏好设置保存失败时保留原语言，并允许重试。

英文模式翻译内置界面、帮助、对话框、校验和无障碍标签。用户填写的备注和心愿名称保持原样。首页记录金额在英文模式为绿色，中文模式为红色。货币显示符号随语言切换（`$` / `¥`），包括累计金额、心愿进度、录入和备份预览。这是显示方式的选择，不进行汇率换算，也不改变记录数值。

`LanguageController` 通过 Android SharedPreferences 通道仅保存 `en` 或 `zh_CN`。`AppStrings` 负责展示翻译；纯 Dart 规则、整数分、数据库结构、CNY 存储和备份格式保持不变。语言属于设备偏好，不包含在记录备份中。未新增依赖。

## 验证与交付

- `flutter analyze`：通过。
- 9 项语言回归测试全部通过，覆盖双向切换、每条记录的颜色与符号、备注和数值不变、重启、偏好写入失败、英文计算／校验／保存、备份预览／导出且 CNY 数据不变、360dp 手机、大字体和平板布局。
- 当前工作树全套测试：204 项通过，5 项失败。五项均为现有 `pig_room_test.dart` 对首页等级标签的断言，该标签已在另一轮首页小猪修改中移除。语言回归测试通过；不声称全套测试通过。
- [本地评审总览](screenshots/language-review.png)：以虚构数据进行的真实 Flutter 组件渲染，逻辑尺寸 390 × 844。桌面预览使用主机中文字体替代。Figma 额度耗尽后，用户已允许改用本地预览，并明确确认审阅完成。
- Android 16／CGL-W00：在独立 `.languageuitest` 包中通过原生运行器验收，结果为 `OK (1 test)`，入口为 `integration_test/language_test.dart`，使用真实 SQLite 和 SharedPreferences，验证语言切换、偏好重新加载、记录不变及每条记录的符号／颜色。[英文首页](screenshots/language-device-en-home.png)和[英文帮助](screenshots/language-device-en-help.png)为使用虚构数据和 Android 字体的设备渲染截图。`tools/language-device.init.gradle` 指定独立包名，避开现有 `.uitest` 安装使用不同签名的问题。
- 先以 780 × 1688 px、320 dpi 验证手机布局，随后恢复原有 2032 × 3048 px、400 dpi 和自动旋转，并检查普通平板启动。
- 从仅包含本任务暂存改动的源码快照构建 ARM、ARM64、x86_64 release APK（56.8 MB）。未完成的心愿绑定修改保留在工作区，不包含在本次交付中。普通应用 `adb install -r` 成功，已检查冷启动、英文保持、既有累计／心愿进度及音效偏好，未增删记录；最后恢复为中文。
- APK：`build/app/outputs/flutter-apk/app-release.apk`，SHA-256 为 `71ff9d14e70c2d029ac1da6f009048f974080a74794801f642b97154361d4ee5`。应用版本保持 `0.5.0+5`，未发布 release。
- 尚未配置 Git 远程；确认远程前无法完成远程交付。
