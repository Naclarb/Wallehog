# Android 发布签名

[English](ANDROID_RELEASE.md) · [简体中文](ANDROID_RELEASE.zh-CN.md)

## 必需配置

发布构建必须使用持久保存、私下备份的密钥库。禁止每次构建重新生成或提交密钥库。调试构建保留 Flutter 的普通开发签名。发布构建缺少以下环境变量时会失败：

- `WALLEHOG_KEYSTORE_PATH`：密钥库绝对路径。
- `WALLEHOG_STORE_PASSWORD`、`WALLEHOG_KEY_ALIAS`、`WALLEHOG_KEY_PASSWORD`：密钥库凭据。

GitHub Actions 还需要仓库 secret `WALLEHOG_KEYSTORE_BASE64`（同一密钥库的 base64）、上述三个凭据 secret，以及纳入版本控制的指纹文件 `android/release-certificate.sha256`。通过 `keytool -list -v` 查询所选别名的证书并与指纹文件中的 SHA-256 值核对。更换签名身份必须审阅指纹变更。密钥库、凭据及私密备份均放在仓库外。缺失配置会阻断发布，不会回退到临时密钥。

只有获得授权的仓库管理员才能配置 GitHub secrets。当前 GitHub 连接器不提供 secrets 管理能力。本地仓库目前没有远程，不能假定此工作流已部署。

## 验证与发布

使用新版本标签（`vX.Y.Z` 或预发布标签），或手动触发工作流并填写新标签。已有发布会被拒绝，禁止覆盖或删除附件。构建号使用 1000 加工作流运行序号；迁移或替换工作流时需保持递增。

通用 APK 包含 armv7、arm64、x86_64。发布签名显式启用 v1、v2、v3 以兼顾兼容性。尚未证明单独缺少 v1 就会导致本次安装失败。`tools/verify_apk.py` 检查 ZIP 完整性、Android 验签、三种签名、唯一签名者、固定证书指纹，并拒绝 Android 调试证书。检查对象必须是最终分发副本，而非中间 APK：

```sh
python tools/verify_apk.py Wallehog-Android.apk --apksigner /path/to/apksigner --certificate-sha256 CERTIFICATE_SHA256
python -m unittest discover -s tools -p test_verify_apk.py
```

工作流在一次性 Android 16 模拟器上安装并启动同一 APK，再用 `adb install -r` 检查覆盖安装；创建新发布前再次校验哈希。模拟器检查不能替代真机验收。冒烟脚本拒绝在物理设备运行，不卸载或清除用户数据。

## 已有预览版与迁移

2026-11-06 排查发现，`v0.5.0-prealpha.1` 首先发布通用 APK，随后提交 `94d552f` 将其替换为 arm64 APK。CI 使用临时调试密钥，且没有签名或安装门禁。下载的当前附件 SHA-256 为 `f59afe873c6693faaf530bdca6a01f25dc2354b129af4eef9d5acc494a200363`，v2 验签有效，证书有效期为 2026-10-28 至 2056-10-20，没有 v1/v3 签名。用户遇到的“未包含任何证书”提示尚未复现；完成安装验收前，不得将这些发布防护描述为已验证解决该具体故障。

无法从 APK 恢复旧 CI 私钥。新持久签名不能静默覆盖使用不同旧签名的安装。保留现有安装；用户决定迁移前先导出备份。禁止自动卸载或清除数据。旧发布保留用于识别；修复包使用新版本发布并说明迁移限制。

## 本地验证（2026-11-06）

- `flutter analyze` 通过；`flutter test` 190 项通过；发布校验回归测试 8 项通过。
- 缺少签名凭据的构建按预期在 `verifyReleaseSigning` 失败。
- 持久本地密钥签名的通用 release APK 构建成功，通过 v1/v2/v3 及固定证书指纹检查。SHA-256：`604ebcb5d1becdbdb1144e5237de7e848fbedeed38680b646e57a5ad13356e0b`。
- 使用相同签名配置单独构建的 `.uitest` release 在连接的 CGL-W00 上通过首次安装、`adb install -r` 和两次冷启动。日常安装保留原签名及数据；旧证书不同，无法安全覆盖交付新签名正式包，该交付仍待完成。
- 持久私钥及凭据保存在 `C:/Users/12113/.android/wallehog-release`，仅本机 Windows 用户和 SYSTEM 可访问。Git 中没有私密材料，仍需独立私密备份。
- 尚未配置 GitHub secrets，修复包未发布；完整 GitHub 模拟器及发布工作流尚未运行。本地 Git 凭据管理器没有可用 GitHub 凭据，连接器无法管理 secrets。

修复已推送至开发分支 `codex/apk-signing-fix`，远程提交为 `8ca87f139c6c00c4b8b76975477f6d17c2e971a2`，见[草稿 PR #1](https://github.com/Naclarb/Wallehog/pull/1)。仅在公开仓库历史上应用发布相关文件，未推送本地其他任务改动。
