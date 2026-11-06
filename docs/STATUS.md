# Current Status

[English](STATUS.md) · [简体中文](STATUS.zh-CN.md)

Updated: 2026-11-06.

## Home pig label adjustment

- Removed the level label beneath the home pig while preserving its position, tap response, and growth rules.
- Figma synchronization is blocked by the Starter-plan MCP call limit. Design review confirmation, APK build, and ordinary-device delivery remain pending.
- Formatting passed. Full analysis reports an unnecessary import in the existing language controller; growth and coin-flow widget tests time out during application startup.

## Product and current work

- The user has declared the MVP complete. The latest work concerns maintainability and collaboration, not another feature milestone. The public README still labels distribution as Pre-alpha; MVP completion does not change that release label.
- The local application version is `0.5.0+5` in `pubspec.yaml`. This repository setup creates no new application version or device installation.
- Product decisions and implementation evidence remain in the documents linked from the [index](README.md). Their historical validation results have not been rerun in this task.

## Layout review

- Application source and tests already follow the documented responsibilities. Inspection found no forbidden upward imports in domain/data or business imports in the character renderer.
- The layout now also identifies app composition, development tools, promotional projects, and generated working directories. Navigation separates present handoff information from requirements and historical evidence; source files and historical reports retain their paths.
- Agent instructions and new navigation/status documents are paired in English and Chinese. Untouched legacy documents have not all been translated.

## Repository handoff

- Wallehog now has its own Git repository at `C:/blog/vibecoding/Wallehog/.git`, on `codex/standalone-repository`. Git commands inside this project use this repository.
- The initial commit records the current project snapshot, including source, assets, tests, documentation, tools, and promotional material. Ignored build outputs, local settings, private inputs, and experiments remain outside this snapshot.
- The `C:/blog` parent repository and its history/index were left unchanged; its existing tracking of Wallehog remains. This independent repository starts a new history and does not import the parent history.
- No remote is configured and no push was performed. The GitHub address in the README is reachable, but remote ownership, history reconciliation, and connection remain pending confirmation.
## Figma layout review

- The user selected the `Figma` connection and requested review of all primary pages inside Codex before physical-device acceptance.
- [Review file](https://www.figma.com/design/CE0fcYnBBxRVcE1ORXw08P), page `01 · 全部主要页面 · 待批注`, contains 17 editable 390 × 844 phone frames: home and empty state, compact/expanded entry, record editing and failure, wish creation/editing, swipe/delete/clear states, help, backup preview/confirmation, recovery, and legacy record editing. Frame numbers identify feedback targets.
- This is a source-based layout reference with fictional data, not a running Flutter prototype or pixel-identical capture. Existing wish assets are retained; the pig uses a simplified source-based vector reference. Representative compositions were visually checked, with icon contrast and alignment corrected. Application code is unchanged.
- User annotations and explicit completion of design review are pending. Use the ordinary Design file's **Comment** tool, not paid annotations or Dev Mode. In the Codex browser, the file showed **Free** and the **Comments** panel opened without an upgrade prompt. The Figma connector does not expose comment retrieval; the browser comments panel can be inspected instead. No APK build, installation, or physical-device acceptance has been performed for this review.
- The focused home-pig widget test passed: no level label, pig retained, and tap response available.
