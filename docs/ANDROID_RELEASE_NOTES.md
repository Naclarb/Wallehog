Android Pre-alpha / Android 早期预览版

Persistent release signing; v1/v2/v3 verification and Android 16 emulator installation/startup checks are required before publication. Source and signing details: docs/ANDROID_RELEASE.md.

使用持久发布签名；发布前必须通过 v1/v2/v3 验签及 Android 16 模拟器安装、启动检查。源码及签名说明见 docs/ANDROID_RELEASE.zh-CN.md。

Older development-signed installations may use a different certificate and cannot be updated in place. Export a backup before deciding to migrate. Never uninstall or clear existing app data without a verified backup. This release does not migrate signing identities automatically.

旧开发签名安装可能使用不同证书，无法覆盖升级。决定迁移前先导出备份；没有验证过的备份时，不要卸载或清除已有应用数据。本版本不会自动迁移签名身份。
