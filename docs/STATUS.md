# Current Status

[English](STATUS.md) · [简体中文](STATUS.zh-CN.md)

Updated: 2026-11-10.

## Wish binding delivery

- First-wish adoption and icon/image binding controls are implemented. Only creation when no wishes exist adopts unbound records; additional creation/switching does not transfer records. Details and evidence: [wish binding](WISH_BINDING.md).
- On 2026-11-06, static analysis and all 210 tests passed after language/home integration. Native Android instrumentation passed at phone and original tablet sizes. The ordinary app was updated with `adb install -r`, cold startup succeeded, and existing visible totals/progress/settings were preserved. Original display and rotation settings were restored.
- On 2026-11-10, acceptance evidence was committed and the task was reconciled with the now-established `main` and confirmed `origin`. The task branch is `codex/wish-binding-review`; no release is published. Later pig-layout and widget changes from `main` are preserved; static analysis and all 218 tests pass for the combined source. These checks are separate from the November 6 installed APK. Figma remains deferred by user instruction.

## Home-screen widget

- The default footprint is now **2 × 2 launcher cells**, following the current home wish. Only **+ → amount keypad → Save** is available; wish creation/editing/switching stay in the app. [Scope, architecture and evidence](HOME_WIDGET.md).
- Reproduced the loading failure on the real Honor launcher: its substituted Button rejects the RemoteViews `setEnabled` call. Removing click actions during submission replaces that call while receiver-side input locking remains. The actual launcher now displays the card and saved-state updates.
- Static analysis, 8 widget-service regressions, the final arm64 release build, compact native acceptance and 2 additional cross-package/real-launcher checks passed. Phone-sized captures are 156 × 156dp. The ordinary app was updated with `adb install -r` and cold startup confirmed; no data clearing, migration, new dependency or release publication. Display settings were unchanged and temporary diagnostic settings restored.
- Existing test-package records are preserved and test applications/providers have explicit Test labels. Remove the old widget and add **Wallehog**, not a Test provider, to apply the new default span. Fix branch: `codex/widget-add-2x2`; integration target: `main`. Other tasks' status is unchanged.

## Repository synchronization

- Confirmed remote: `origin`, `https://github.com/Naclarb/Wallehog.git`. `codex/language-switch` tracks its same-name remote branch; ordinary `git push` works after committing changes.
- The user requested uploading the current working tree, including the wish-binding implementation checkpoint. Formatting (15 Dart files), `flutter analyze`, 32 focused controller/storage/migration/widget tests, and `git diff --check` passed. Design review and physical-device delivery remain pending; this source synchronization does not publish an APK or complete application acceptance.
- Integration target: `main`, explicitly authorized by the user. Source checkpoint `35c3448` and merge `7301599` join the independent histories, retaining the current local project tree and remote `main` commit `94d552f` as an ancestor. The merge changes no project files. The local tree has no release workflow, so this synchronization does not run the old workflow that overwrote existing APK assets. No force push is needed. Synchronization branch: `codex/repository-sync`; application acceptance remains pending independently of source integration.

## Interface language

- Help now offers Simplified Chinese / English switching with a persistent device preference. English uses `$` notation and green home-record amounts; Chinese restores `¥` and red. Recorded values and CNY storage are unchanged.
- The user approved local preview review. Static analysis, 9 language regressions and native Android acceptance passed. The release APK was installed with `adb install -r` and cold startup, language persistence and existing data were checked. Original display settings were restored. Full-suite limitations and evidence are recorded in [Interface language](LANGUAGE.md).
- Original delivery branch: `codex/language-switch`, feature commit `d5faaba`. Its source is included in the repository synchronization above. Wish-binding acceptance remains unfinished.

## Home pig label adjustment

- Removed the level label beneath the home pig while preserving its position, tap response, and growth rules.
- Follow-up: reduced the pig box and home header reservation from 78dp to the pig's 62dp height, and aligned drag bounds with that height. Formatting, static analysis and all 7 focused pig/growth/coin-flow tests passed, including matching the container bottom to the pig bounds. Visual review and device delivery remain pending for this follow-up.
- This adjustment is included in the ordinary-app language delivery. The earlier Figma quota block was bypassed with the user's authorized local preview workflow.
- Latest analysis and growth/coin-flow checks pass. Five older `pig_room_test.dart` cases still expect the removed level label; the full-suite limitation is recorded in the language verification.

## Product and current work

- The user has declared the MVP complete. The latest feature delivery adds English language switching; the public distribution label remains Pre-alpha.
- The local application version remains `0.5.0+5` in `pubspec.yaml`; the language update was delivered in place without publishing a release.
- Product decisions and implementation evidence remain in the documents linked from the [index](README.md). Their historical validation results have not been rerun in this task.

## Layout review

- Application source and tests already follow the documented responsibilities. Inspection found no forbidden upward imports in domain/data or business imports in the character renderer.
- The layout now also identifies app composition, development tools, promotional projects, and generated working directories. Navigation separates present handoff information from requirements and historical evidence; source files and historical reports retain their paths.
- Agent instructions and new navigation/status documents are paired in English and Chinese. Untouched legacy documents have not all been translated.

## Repository handoff

- Wallehog now has its own Git repository at `C:/blog/vibecoding/Wallehog/.git`, on `codex/standalone-repository`. Git commands inside this project use this repository.
- The initial commit records the current project snapshot, including source, assets, tests, documentation, tools, and promotional material. Ignored build outputs, local settings, private inputs, and experiments remain outside this snapshot.
- The `C:/blog` parent repository and its history/index were left unchanged; its existing tracking of Wallehog remains. This independent repository starts a new history and does not import the parent history.
- Remote connection and development-branch push were completed on 2026-11-07. The separate remote `main` history is preserved; see repository synchronization above.
## Figma layout review

- The user selected the `Figma` connection and requested review of all primary pages inside Codex before physical-device acceptance.
- [Review file](https://www.figma.com/design/CE0fcYnBBxRVcE1ORXw08P), page `01 · 全部主要页面 · 待批注`, contains 17 editable 390 × 844 phone frames: home and empty state, compact/expanded entry, record editing and failure, wish creation/editing, swipe/delete/clear states, help, backup preview/confirmation, recovery, and legacy record editing. Frame numbers identify feedback targets.
- This is a source-based layout reference with fictional data, not a running Flutter prototype or pixel-identical capture. Existing wish assets are retained; the pig uses a simplified source-based vector reference. Representative compositions were visually checked, with icon contrast and alignment corrected. Application code is unchanged.
- User annotations and explicit completion of design review are pending. Use the ordinary Design file's **Comment** tool, not paid annotations or Dev Mode. In the Codex browser, the file showed **Free** and the **Comments** panel opened without an upgrade prompt. The Figma connector does not expose comment retrieval; the browser comments panel can be inspected instead. No APK build, installation, or physical-device acceptance has been performed for this review.
- The focused home-pig widget test passed: no level label, pig retained, and tap response available.
