# Android 发布签名

[English](ANDROID_RELEASE.md) · [简体中文](ANDROID_RELEASE.zh-CN.md)

官方 APK 使用 `android/release-certificate.sha256` 固定的持久证书。验签固定使用 Android Build-Tools 36.0.0，不随预装 SDK 预览版变化。私钥库和凭据必须在 Git 之外，并保留私有备份。调试证书不得用于官方发布。

本地发布构建需要 `WALLEHOG_KEYSTORE_PATH`、`WALLEHOG_STORE_PASSWORD`、`WALLEHOG_KEY_ALIAS` 和 `WALLEHOG_KEY_PASSWORD`。GitHub Actions 使用相同的三个凭据 Secret，另加 `WALLEHOG_KEYSTORE_BASE64`。缺少凭据时阻断发布构建。密钥和本机 SDK 路径由 Git 忽略，不在日志中输出签名值。

两种 APK 均使用 `pubspec.yaml` 的构建号；分别执行 `--target-platform` 构建，避免按 ABI 拆包产生版本号偏移。官方 ARM64 包与通用包之间切换保持同一证书和版本号。在 `pubspec.yaml` 更新语义版本并递增构建号，然后推送匹配的新 `vX.Y.Z` 标签。工作流核对标签与版本，拒绝覆盖已有 Release，执行分析和测试，构建推荐的 ARM64 包与通用包，验证两者的 ZIP 完整性、固定非调试证书及 v1/v2/v3 签名，检查 ARM64 下载仅含 arm64-v8a，再在 Android 16 模拟器安装、覆盖安装并启动同一通用 APK 后发布。单架构包另由 ARM64 真机验收。稳定标签创建普通最新版，带后缀标签创建预发布版；不替换已发布附件。现有 1.0 通过新增附件提供 ARM64 APK 和 `SHA256SUMS-arm64.txt`，原通用包和校验文件保持不变；后续版本的 `SHA256SUMS.txt` 同时记录两种 APK。

```sh
python -m unittest discover -s tools -p test_verify_apk.py
python tools/verify_apk.py Wallehog-Android.apk --apksigner /path/to/apksigner --certificate-sha256 CERTIFICATE_SHA256
```

验证器支持编号及 v3.1 SDK 区间签名者标签，要求所有应用证书均匹配固定指纹，仍拒绝未批准的密钥轮换和调试证书。它输出最终分发文件的 SHA-256，与 APK 一同发布 `SHA256SUMS.txt`。模拟器冒烟脚本拒绝物理设备，不卸载或清空用户数据。真机验收另在独立包中验证应用与 Widget，再交付日常安装。

旧 Pre-alpha 和本地开发安装可能使用不同证书，无法从 APK 恢复其私钥。Android 拒绝不同证书的覆盖升级。选择迁移前先导出并验证 JSON 备份，不自动卸载或清空数据。语言与音效偏好不在记录备份中，须另外核对。可从同一源码制作私有兼容签名包，覆盖已有开发安装；公开 APK 始终使用正式证书，私有包不得作为官方附件上传。

当前发布与验证结果见 [STATUS](STATUS.zh-CN.md)。设备专属证据和私有签名位置仅保留本地。
