# Wallehog

[English](README.md) · [简体中文](README.zh-CN.md)

A small, offline Android companion for mindful spending choices. Tap **+ → enter an amount → confirm**, watch your wish progress, and share a little moment with your piggy bank.

**Pre-alpha · Android APK only.** Features and appearance may change. The current interface is primarily Simplified Chinese.

Wallehog records savings you report yourself. These amounts are **not deposits, bank balances, or spendable funds**. No mandatory budgets or categories, no streak penalties, no accounts, ads, banking connections, or telemetry. Records stay in local SQLite; you can edit, delete, export, and restore them.

## Preview

390 × 844 Flutter-rendered phone previews using fictional demo data (not photographs or physical-device captures).

<img src="docs/public/home.png" width="280" alt="Wallehog home with a wish, pig and saved amount"> <img src="docs/public/calculator.png" width="280" alt="Quick amount entry">

## Android download

Download the APK from [Releases](https://github.com/Naclarb/Wallehog/releases). No iOS, desktop, or web release is provided. Pre-alpha APKs currently use a development signing key; future signing changes may prevent in-place upgrades. Export a backup before changing installations. Never uninstall an existing copy without backing up its data.

## Run and build

Validated toolchain: Flutter **3.47.7** (Dart **3.13.5**), JDK **17**, Android SDK. Install the SDK/NDK requested by Flutter and accept Android SDK licenses. Gradle wrapper and `pubspec.lock` are committed. Dependency downloads require internet; app operation does not.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`. Local SDK paths are generated on your machine and must not be committed. Tests use system SQLite; Windows uses `winsqlite3`, and other hosts need an available system SQLite library. Reproducible setup does not imply byte-identical APKs across signing keys and machines.

## Limitations and license

Early software: limited device coverage, no cloud synchronization, and no guarantee against data loss. Backups are unencrypted JSON; store them privately. Screenshots are demo previews. The bundled controller illustration resembles a game controller; no brand affiliation is implied.

Source code: [MIT](LICENSE), as already selected in this repository. Third-party and asset details: [Credits](docs/public/CREDITS.md). Only runtime assets, tests, build configuration and essential public documentation are included; discarded experiments, private data and development archives are excluded.
