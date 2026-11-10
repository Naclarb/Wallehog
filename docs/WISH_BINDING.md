# Wish Binding Fix

[English](WISH_BINDING.md) · [简体中文](WISH_BINDING.zh-CN.md)

Updated: 2026-11-06. Implementation checkpoint; design review and device delivery remain pending.

## Confirmed behavior

The user's clarification on 2026-11-06 supersedes PRODUCT_SPEC W01–W02 only for these cases:

- If there are no wishes, creating the first wish adopts every unbound record in the same transaction. This also applies after all wishes have been cleared. Existing records and total savings are preserved.
- Creating another wish or switching among existing wishes does not adopt or transfer records.
- New records default to the current wish. The details area below note and date includes an icon-only binding control: a link icon plus the selected wish image, or a crossed-circle icon for unbound. Its compact rounded picker shows only already-created wishes and an unbound tile, using images without persistent text labels. Wish names remain available to screen readers and on long press. Editing initializes from the record's original binding. Selection is local until the record is saved; cancelling leaves storage unchanged.
- Saving an edit updates amount and binding atomically. A record belongs to at most one wish, and total savings count it once. Failed writes retain input; committed writes with failed snapshot reads use the existing recovery lock and reread without replay.

## Implementation

SQLite schema remains v4 and backup format remains v2. Explicit assignments in `goal_records` determine progress. Assigning an older record lowers the destination wish's `start_after_id` as needed so existing domain and v2 backup validation remain valid. It does not infer assignments for other records. AUTOINCREMENT identity, creation time, request token, and other wishes' assignments remain unchanged. Existing legacy migrations retain their historical boundaries.

The repository's `save` accepts `updateGoal` and nullable `goalId`. Without `updateGoal`, new records use the selected wish and edits preserve binding. With it, null explicitly unbinds. Repeated creation tokens cannot duplicate or silently change binding.

## Design review

On 2026-11-06 the user requested icon/image controls and removal of redundant name/target placeholders, then explicitly authorized completing code without waiting for Figma. The wish editor keeps the existing field icons and accessible names but removes the visible placeholders. No new icon font package is needed: Material Icons are already bundled.

![Current Flutter preview: unbound entry, image picker, and wish creation](screenshots/wish-binding-icons.png)

This is a 390 × 844 Flutter-rendered preview with fictional data and locally loaded preview fonts, not device evidence. It shows the current implementation.

[Review area, frames 18–21](https://www.figma.com/design/CE0fcYnBBxRVcE1ORXw08P?node-id=12-12) retains complete 390 × 844 screens with editable text, vectors, and a shared binding-row component. It is a layout proposal using fictional data, not a running app. The existing review page and ordinary Design comments avoid paid annotations and Dev Mode.

The earlier text-based review was checked in the previous checkpoint. Starter MCP quota is still exhausted. The shared binding component was partially updated through the ordinary free browser editor, but the picker, unbound example, and wish editor in Figma have not been synchronized with this iteration. Per user instruction, further Figma work is deferred; use the current local preview above. The user subsequently requested device acceptance; results are below. The connector has no comment retrieval tool.

## Device acceptance and delivery

Acceptance ran on 2026-11-06 after the user explicitly requested physical-device validation. The completed installed build includes the language-switch and home-pig-label changes merged in `0b18213`.

- Static analysis passed and all 210 automated tests passed after integration. Legacy home-level assertions were aligned with the already-approved hidden label.
- Android native instrumentation passed `OK (1 test)` at both phone settings (780 × 1688 px, 320 dpi) and the original tablet settings (2032 × 3048 px, 400 dpi). The dedicated `.wishbindinguitest` package used new fictional SQLite data, never the ordinary database. The test covers unbound recording, first-wish adoption, no transfer on additional creation/switching, image-only selection, editing/rebinding, stable totals, backup round trip, database reopen and English accessibility.
- Device captures: [picker](screenshots/wish-binding-device-picker.png), [creation](screenshots/wish-binding-device-create.png), [unbound](screenshots/wish-binding-device-unbound.png), [English picker](screenshots/wish-binding-device-english-picker.png), [tablet picker](screenshots/wish-binding-device-tablet-picker.png). These contain fictional test records.
- Restored the original resolution, density, automatic rotation (`1`) and user rotation (`1`).
- The ordinary `dev.wallehog.wallehog` release APK was updated with `adb install -r` successfully, with no uninstall or data clearing. Cold startup succeeded; visible existing savings, selected wish progress and Chinese preference matched the pre-install check. First-install timestamp was unchanged. Ordinary screenshots stayed in ignored private logs.
- Delivered APK version: `0.5.0+5`; SHA-256: `5fdd7f6961be364909bb54ba0ea23d87c33e403b8c54a80d39f3e9e3e9d5cc94`. This records the November 6 installation, not a new installation on November 10.

Source delivery is being reconciled with the now-established `main` and confirmed `origin`; current integration/push status is recorded in [STATUS](STATUS.md). No release is published. Figma remains deferred at the user's request.
