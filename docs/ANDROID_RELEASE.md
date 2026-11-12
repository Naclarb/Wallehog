# Android release signing

[English](ANDROID_RELEASE.md) · [简体中文](ANDROID_RELEASE.zh-CN.md)

Official APKs use the persistent certificate pinned in `android/release-certificate.sha256`. Verification uses Android Build-Tools 36.0.0 instead of whichever SDK preview happens to be preinstalled. Keep the private keystore and credentials outside Git and maintain a private backup. Debug certificates cannot be published as official releases.

Local release builds require `WALLEHOG_KEYSTORE_PATH`, `WALLEHOG_STORE_PASSWORD`, `WALLEHOG_KEY_ALIAS` and `WALLEHOG_KEY_PASSWORD`. GitHub Actions uses the same three credential secrets plus `WALLEHOG_KEYSTORE_BASE64`. Missing credentials block release builds. Secrets and local SDK paths are ignored; never print signing values in logs.

Both APKs use the version code from `pubspec.yaml`; separate `--target-platform` builds avoid split-per-ABI version-code offsets. Switching between the official ARM64 and universal packages preserves the signing identity and version code. Update `pubspec.yaml` with a new semantic version and increasing build number. Push a matching new `vX.Y.Z` tag. The workflow checks the tag/version, rejects existing releases, runs analysis and tests, builds recommended ARM64 and universal APKs, verifies both ZIPs and v1/v2/v3 signatures against the pinned non-debug certificate, checks that the ARM64 download contains only arm64-v8a, and installs/reinstalls/starts the exact universal APK on an Android 16 emulator before publication. Physical ARM64 acceptance covers the single-architecture build. Stable tags create a normal latest release; tags with a suffix create a prerelease. Published assets are not replaced. For the existing 1.0 release, the ARM64 APK and `SHA256SUMS-arm64.txt` are appended as new assets; the original universal APK and checksum remain unchanged. Future releases publish both APK digests in `SHA256SUMS.txt`.

```sh
python -m unittest discover -s tools -p test_verify_apk.py
python tools/verify_apk.py Wallehog-Android.apk --apksigner /path/to/apksigner --certificate-sha256 CERTIFICATE_SHA256
```

The verifier accepts numbered and v3.1 SDK-range signer labels, requiring every reported application certificate to match the pin; unapproved key rotation and debug certificates remain rejected. It emits the final distribution file's SHA-256. Publish that file and `SHA256SUMS.txt` together. Emulator smoke checks reject physical devices and never uninstall or clear user data. Physical-device acceptance additionally exercises the application and widget in isolated packages before ordinary-app delivery.

Older pre-alpha and local development copies may have different signing certificates; the APK cannot recover their private keys. Android rejects an in-place update signed by a different certificate. Export and validate a JSON backup before choosing a migration; do not uninstall or clear existing data automatically. Language and sound preferences are outside the record backup and must be checked separately. A private compatibility-signed build from the same source may update an existing development installation while the public APK retains the official certificate; that private build is never uploaded as an official release.

Current release and verification results are in [STATUS](STATUS.md). Device-specific evidence and private signing locations remain local.
