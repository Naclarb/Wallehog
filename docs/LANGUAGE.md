# Interface language

[English](LANGUAGE.md) · [简体中文](LANGUAGE.zh-CN.md)

Help → Language offers **简体中文** and **English**, with Simplified Chinese as default. A successful change takes effect immediately, stays on Help, refreshes widgets and persists after restart. Failed preference writes retain the previous language and allow retry.

English translates built-in text and accessibility labels. User notes and wish names stay unchanged. Home record amounts are green in English and red in Chinese. Display symbols follow the language (`$` / `¥`), without currency conversion or changes to stored numbers. Storage remains integer CNY minor units.

`LanguageController` saves `en` or `zh_CN` in Android SharedPreferences; `AppStrings` handles presentation. Language is a device preference outside record backups. No dependency or database migration is required. Regression coverage includes both directions, persistence/failure, amounts, entry, backup, narrow screens, large text and tablet layouts. Current results: [STATUS](STATUS.md).
