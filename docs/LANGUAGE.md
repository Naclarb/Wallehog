# Interface language

[English](LANGUAGE.md) · [简体中文](LANGUAGE.zh-CN.md)

Updated: 2026-11-06.

Help → Language offers **简体中文** and **English**. Simplified Chinese is the default. A successful selection takes effect immediately, stays on Help, and is remembered after restart. Failed preference writes keep the previous language and allow retry.

English translates built-in UI, help, dialogs, validation and accessibility labels. User-written notes and wish names stay as entered. Home record amounts are green in English and red in Chinese. Displayed currency notation follows the language (`$` / `¥`), including totals, wish progress, entry and backup preview. This is a display choice, with no exchange-rate conversion or changes to recorded numbers.

`LanguageController` stores only `en` or `zh_CN` through an Android SharedPreferences channel. `AppStrings` localizes presentation; pure Dart rules, integer minor units, database schema, CNY storage and backup format stay unchanged. Language is a device preference, outside record backups. No dependency was added.

## Verification and delivery

- `flutter analyze`: passed.
- All 9 language regression tests passed. They cover switching both ways, all record colors/symbols, unchanged notes/amounts, restart, failed preference writes, English calculation/validation/save, backup preview/export with unchanged CNY data, 360dp phone, large text and tablet layouts.
- Full working-tree suite: 204 passed, 5 failed. All five are existing `pig_room_test.dart` assertions for the home level label removed in the separate home-pig change. The language regression tests passed; the suite is not reported as fully passing.
- [Local review sheet](screenshots/language-review.png): actual Flutter widget rendering at 390 × 844 logical pixels with fictional data. Desktop preview uses a host Chinese font substitute. The user authorized local preview after Figma quota exhaustion and then explicitly confirmed review completion.
- Android 16 / CGL-W00: native instrumentation passed `OK (1 test)` using `integration_test/language_test.dart`, real SQLite and SharedPreferences, in the separate `.languageuitest` package. It verifies language switching, persisted preference reload, unchanged records and every record's symbol/color. [English home](screenshots/language-device-en-home.png) and [English help](screenshots/language-device-en-help.png) are device-rendered captures with fictional data and Android fonts. `tools/language-device.init.gradle` selects this package, avoiding the existing `.uitest` installation's different signing certificate.
- Phone-first validation used 780 × 1688 px at 320 dpi. The original 2032 × 3048 px, 400 dpi and automatic rotation were restored; normal tablet startup was then checked.
- Release APK built for ARM, ARM64 and x86_64 (56.8 MB) from a source snapshot containing only this task's staged changes. Unfinished wish-binding edits remain in the working tree and are excluded from this delivery. `adb install -r` succeeded for the ordinary app; cold startup, English persistence, existing totals/wish progress and sound preference were checked without adding/deleting records. Chinese was restored afterward.
- APK: `build/app/outputs/flutter-apk/app-release.apk`, SHA-256 `71ff9d14e70c2d029ac1da6f009048f974080a74794801f642b97154361d4ee5`. App version remains `0.5.0+5`; no release was published.
- No Git remote is configured; remote delivery cannot be performed until a remote is confirmed.
