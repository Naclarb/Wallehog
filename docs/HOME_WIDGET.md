# Home-screen widget

[English](HOME_WIDGET.md) · [简体中文](HOME_WIDGET.zh-CN.md)

Updated: 2026-11-10. Development branch: `codex/home-widget`; integration target: `main`.

## Approved scope

The widget keeps the user's wish visible on the Android home screen, encouraging return visits. It complements the app rather than replacing it. Its default card follows the wish currently selected on the application's home page, using the existing illustration, soft card and progress ring. Creating, editing and switching wishes remain application functions. Tapping the title or illustration opens the app.

The only widget workflow is adding a savings amount: **+ → numeric keypad → Save → card**. The keypad appears only during entry. There is no wish selector, note, date editor, expression calculator, record history or character animation. With no wish, entries remain unbound, following the application's existing rules. Numbers are self-reported savings, not deposits or an account balance.

## Implementation

- Android `AppWidgetProvider` and `RemoteViews` render the card and button keypad. No new runtime dependencies or database migration are required. The layout starts at 4 × 4 cells, with a 250 × 300dp minimum; launcher grids and padding can change its physical size.
- `HomeWidgetBridge` publishes the application's consistent controller snapshot after changes. Language follows the device's existing application preference. Returning to the application reloads its snapshot. Android also requests periodic widget refreshes; operating-system restrictions can delay them.
- When an application controller exists, widget requests use it. Otherwise a short-lived, UI-free Flutter engine runs `widgetMain`, using `HomeWidgetService`, `RecordsController` and the existing SQLite repository. Pressing widget keys and saving do not launch an Activity.
- Amounts remain integer minor units with existing validation and limits. The native draft persists its amount, target wish, request token and occurrence date before submitting. An unconfirmed submission remains immutable; Retry uses that same request. The repository's unique client token prevents duplicate records, and recovery reads the committed snapshot before accepting another write.
- If the current wish changes during entry, saving requests review of the new wish before submitting. Successful acknowledgement returns to the card. These safeguards do not change application wish selection or growth rules.
- Each placed widget has an independent draft. Removing a widget discards its draft, not saved records. Native bitmaps adapt to display density and are bounded to 512 × 512 pixels.

## Verification

Implementation checks: Dart formatting, `flutter analyze`, 149 focused application/data/domain/wish-binding/language tests, and arm64 release APK compilation passed. Eight new service tests cover idempotency, wish changes, unbound entry, storage failure, post-commit recovery, restart, concurrent operations and invalid input.

Native acceptance passed on the connected CGL-W00: `OK (1 test)`, 27.428 seconds, in the isolated `.widgetuitest` package. Its `AppWidgetHost` test exercises actual `RemoteViews` PendingIntents, checks exact SQLite count/amount changes, detects a changed wish, verifies cancellation and English, and confirms that background entry launches no Activity. Saving also works with the application open; the foreground controller can still read after idle worker teardown. Test reruns preserve existing isolated records and check deltas. The ordinary database is outside this package.

Original display: 2032 × 3048, density 400, font scale 1.0. Phone validation used 1080 × 2400, density 480, with native host captures at 360 × 340dp. Original size/density were restored and verified; font scale was unchanged. The temporary widget-binding permission was revoked and test widget IDs removed.

[Card](screenshots/widget-native-card.png), [amount entry](screenshots/widget-native-entry.png), and [English entry](screenshots/widget-native-en-entry.png) are device-rendered native-host captures. The PS5 card uses fictional preview data; it is not a screenshot of the user's records or of a manufacturer's launcher. Individual launcher placement, resizing and large-font behavior have not been separately accepted. The user adds Wallehog through the home screen's widget picker.

Final arm64 release APK was delivered with `adb install -r` to the ordinary `dev.wallehog.wallehog` installation: `Success`. `am start -W` reported `Status: ok`, `LaunchState: COLD`, and an active process. There was no uninstall, data clearing or database migration. The application version remains `0.5.0+5`; no release has been published.
