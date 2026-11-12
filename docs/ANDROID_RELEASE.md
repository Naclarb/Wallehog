# Android release signing

[English](ANDROID_RELEASE.md) · [简体中文](ANDROID_RELEASE.zh-CN.md)

Official APKs use the persistent certificate pinned in `android/release-certificate.sha256`. Keep the private keystore and credentials outside Git and maintain a private backup. Debug certificates cannot be published as official releases.

Local release builds require `WALLEHOG_KEYSTORE_PATH`, `WALLEHOG_STORE_PASSWORD`, `WALLEHOG_KEY_ALIAS` and `WALLEHOG_KEY_PASSWORD`. GitHub Actions uses the same three credential secrets plus `WALLEHOG_KEYSTORE_BASE64`. Missing credentials block release builds. Secrets and local SDK paths are ignored; never print signing values in logs.

Update `pubspec.yaml` with a new semantic version and increasing build number. Push a matching new `vX.Y.Z` tag. The workflow checks the tag/version, rejects existing releases, runs analysis and tests, builds a universal APK, verifies ZIP integrity and v1/v2/v3 signatures against the pinned non-debug certificate, and installs/reinstalls/starts the exact APK on an Android 16 emulator before publication. Stable tags create a normal latest release; tags with a suffix create a prerelease. Published assets are not replaced.

```sh
python -m unittest discover -s tools -p test_verify_apk.py
python tools/verify_apk.py Wallehog-Android.apk --apksigner /path/to/apksigner --certificate-sha256 CERTIFICATE_SHA256
```

The verifier accepts numbered and v3.1 SDK-range signer labels, requiring every reported application certificate to match the pin; unapproved key rotation and debug certificates remain rejected. It emits the final distribution file's SHA-256. Publish that file and `SHA256SUMS.txt` together. Emulator smoke checks reject physical devices and never uninstall or clear user data. Physical-device acceptance additionally exercises the application and widget in isolated packages before ordinary-app delivery.

Older pre-alpha and local development copies may have different signing certificates; the APK cannot recover their private keys. Android rejects an in-place update signed by a different certificate. Export and validate a JSON backup before choosing a migration; do not uninstall or clear existing data automatically. Language and sound preferences are outside the record backup and must be checked separately. A private compatibility-signed build from the same source may update an existing development installation while the public APK retains the official certificate; that private build is never uploaded as an official release.

Current release and verification results are in [STATUS](STATUS.md). Device-specific evidence and private signing locations remain local.
