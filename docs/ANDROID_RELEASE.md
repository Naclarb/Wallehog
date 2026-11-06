# Android release signing

[English](ANDROID_RELEASE.md) · [简体中文](ANDROID_RELEASE.zh-CN.md)

## Required configuration

Release builds require a persistent, privately backed-up keystore. Never regenerate it per build or commit it. Debug builds retain Flutter's ordinary development signing. Release builds fail without these environment variables:

- `WALLEHOG_KEYSTORE_PATH`: absolute keystore path.
- `WALLEHOG_STORE_PASSWORD`, `WALLEHOG_KEY_ALIAS`, `WALLEHOG_KEY_PASSWORD`: keystore credentials.

GitHub Actions additionally requires the repository secret `WALLEHOG_KEYSTORE_BASE64` (base64 of that same keystore), the three credential secrets above, and the tracked fingerprint in `android/release-certificate.sha256`. Obtain the certificate fingerprint using `keytool -list -v` for the selected alias; compare its SHA-256 value with the tracked fingerprint. Changing signing identity requires a reviewed fingerprint change. Keep the keystore, credentials, and a private backup outside the repository. Missing configuration blocks release rather than falling back to a temporary key.

Only an authorized repository administrator can configure GitHub secrets. The available GitHub connector does not expose secrets administration. The local checkout currently has no remote; do not assume this workflow has been deployed.

## Verification and publication

Use a new version tag (`vX.Y.Z` or a prerelease) or dispatch the workflow with a new tag. Existing releases are rejected; assets are never overwritten or deleted. Build numbers use 1000 plus the workflow run number. Keep this sequence increasing if the workflow is moved or replaced.

The universal APK includes armv7, arm64, and x86_64. Release signing explicitly enables v1, v2, and v3 for compatibility. Missing v1 alone is not proven to explain the reported installer failure. `tools/verify_apk.py` checks ZIP integrity, Android signature verification, all three schemes, exactly one signer, the pinned certificate, and rejection of Android debug certificates. Run it against the final distribution copy, not an intermediate APK:

```sh
python tools/verify_apk.py Wallehog-Android.apk --apksigner /path/to/apksigner --certificate-sha256 CERTIFICATE_SHA256
python -m unittest discover -s tools -p test_verify_apk.py
```

The workflow installs and launches that exact APK on a disposable Android 16 emulator, then tests reinstall with `adb install -r`. It checks the hash again before creating a new release. Emulator checks do not replace physical-device acceptance. The smoke script rejects physical devices and does not uninstall or clear user data.

## Existing pre-alpha and migration

Investigation on 2026-11-06 found that `v0.5.0-prealpha.1` was first published as a universal APK and later replaced with an arm64 APK by commit `94d552f`. CI used temporary debug keys and had no signature or installation gate. The downloaded current attachment has SHA-256 `f59afe873c6693faaf530bdca6a01f25dc2354b129af4eef9d5acc494a200363`, valid v2 signing, and a certificate valid from 2026-10-28 through 2056-10-20. Its v1/v3 signatures are absent. The exact cause of the user's “no certificates” installer message has not been reproduced; these release safeguards must not be described as verified resolution of that specific failure before installation acceptance.

The old CI private key cannot be recovered from the APK. A new persistent signing key cannot silently update an old differently signed installation. Preserve existing installations and export backups before any user-directed migration. Do not uninstall or clear data automatically. Keep the old release available for identification; publish the replacement as a new version with migration notes.

## Local verification (2026-11-06)

- `flutter analyze`: passed; `flutter test`: 190 passed; release verifier regression tests: 8 passed.
- A build without signing credentials failed at `verifyReleaseSigning` as intended.
- A universal release APK built with the persistent local key passed v1/v2/v3 and pinned-certificate verification. SHA-256: `604ebcb5d1becdbdb1144e5237de7e848fbedeed38680b646e57a5ad13356e0b`.
- A separately built `.uitest` release with the same signing configuration passed fresh installation, `adb install -r`, and cold startup twice on the connected CGL-W00. The daily installation retained its original signing identity and data. Its different old certificate prevents safe in-place delivery of the newly signed production APK; that delivery remains pending.
- The private persistent key and credentials are stored under `C:/Users/12113/.android/wallehog-release`, restricted to the local Windows user and SYSTEM. No private material is in Git. An independent private backup is still required.
- GitHub secrets are not configured, and the replacement has not been released. The full GitHub emulator/publication workflow has not been executed. The local Git credential helper has no usable GitHub credential, and the connector cannot administer secrets.
