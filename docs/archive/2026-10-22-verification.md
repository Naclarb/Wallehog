> 上轮未收尾报告存档，不代表当前版本状态；最新结果见 ../VERIFICATION.md。

# M1 验证报告

日期：2026-10-22。范围：核心记录系统；无心愿、成长、动画、账号、网络业务或导出功能。

## 已完成

- 预算内节省、便宜替代、放弃可选购买三类记录；支持创建、编辑、删除与发生日期。
- 两个独立指标；放弃购买固定 0 分、1 次好选择。修改类型或删除后重新从记录聚合。
- 纯 Dart 安全算式解析；四则运算、括号、一元符号、精确小数；最终转换为整数分，检查负值、除零、输入长度和整数边界。
- SQLite schema v1、事务写入、创建时间保护和失败回滚；保存状态不确定时要求重新读取，防止直接重试导致重复记录。
- 中文粉色简洁界面、静态自绘小猪、独立历史页、空状态和输入错误说明。
- Android 禁用系统云备份及设备转移；参考图未作为应用资产打包。

## 环境

采用 Windows 原生开发，工具安装在用户目录；未使用 WSL、未修改系统 JAVA_HOME 或永久 PATH。

| 工具 | 实际版本 / 配置 |
| --- | --- |
| Flutter | stable 3.47.7，用户目录 dev/flutter |
| Dart | 3.13.5 |
| Java | Temurin JDK 17.0.20.1+1，Flutter 单独配置 JDK 路径 |
| Android | SDK API 36、Build Tools 36.0.0；构建自动准备 NDK 28.2.13676358、CMake 3.22.1 |
| Gradle / AGP | 9.3.1 / 9.1.0（Flutter 模板） |
| 真机 | CGL-W00 平板，Android 16 / API 36，arm64，经 USB 调试 |
| 应用 | 0.1.0+1；开发包名 dev.wallehog.wallehog |

Flutter、JDK、Android 命令行工具与 Gradle 下载均校验发布方 SHA-256。开发工具首次安装需要网络，应用运行不需要。工具安装参考：[Flutter](https://docs.flutter.dev/install/manual)、[Android 命令行工具](https://developer.android.com/studio#command-tools)。可选 Maven 镜像只通过 tools/dev-shell.ps1 的显式开关启用。

## 验证结果

| 检查 | 结果 |
| --- | --- |
| Dart 格式化 | 已执行；最终无改动检查随交付执行 |
| flutter analyze | 通过，无问题 |
| flutter test | 75 项通过，包括领域、控制器、真实桌面 SQLite 与 widget 测试 |
| Android debug APK | 构建通过 |
| Android 原生集成测试 | 1 项通过，0 失败、0 错误、0 跳过；包含真实 SQLite / UI 增改删与数据库重开 |
| Android release APK | 最终构建与安装结果待本轮验证结束后补记 |

设备测试 XML：`build/app/outputs/androidTest-results/connected/debug/TEST-CGL-W00 - 16-_app-.xml`。原始构建与测试日志在 `.buildlog/`；这些机器产物不提交。

## 遇到的问题与处理

- 官方 Gradle 地址跳转后连接受阻：镜像下载后以官方 checksum 校验，项目仍保留标准分发地址；Maven 使用显式启用的镜像辅助首次下载。
- 桌面测试默认下载 SQLite 二进制失败：按依赖支持的配置使用系统 SQLite，Windows 为 winsqlite3；Android 使用 sqflite，不新增应用网络逻辑。
- 平板普通 Flutter 测试无法通过 logcat 发现 VM 服务：使用 Flutter 官方支持的 Android 原生测试运行器。原生测试成功，但无法收集测试 logcat，报告如实保留该警告。
- 初次 release 的插件注册文件与测试构建冲突：最终采用串行构建，release 执行完整 Flutter 工具准备，不复用测试注册文件。切换构建模式时不要使用可能跳过注册更新的 `--no-pub`。
- Gradle 保留 SDK 模板/Flutter 插件的弃用警告；当前版本构建可用，不为消除外部警告改写 SDK 或提前升级 AGP 10。

## 当前限制与下一步

只验证当前一台平板；尚未进行广泛机型、TalkBack 人工体验或大规模历史性能验证。金额仅人民币；目前读取全量记录。没有备份/导出，卸载可能丢失数据；集成测试可能清理测试应用，勿对有重要记录的安装直接运行。正式包名、开源许可证、发布签名与启动图标仍需发布前确定，release 当前为开发签名。

建议下一里程碑先复核 D05/D06，交付一个心愿目标与明确的激励进度说明；随后实现本地导出恢复。动画继续后置。
