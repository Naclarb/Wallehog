# Home-screen widget

[English](HOME_WIDGET.md) · [简体中文](HOME_WIDGET.zh-CN.md)

Updated: 2026-11-10. Fix branch: `codex/widget-add-2x2`; integration target: `main`. Initial implementation: `23ea269`.

## Approved scope

The widget keeps the user's current wish visible on the Android home screen. It complements the application: creating, editing and switching wishes stay in the app. Tapping the title or illustration opens the app. The default footprint is **2 × 2 launcher cells**, matching two application-icon positions in each direction; cell dimensions vary by launcher. Existing widgets may retain their old span and should be removed and added again.

The only widget workflow is **+ → numeric amount keypad → Save → card**. Entry happens inside the widget without opening the application's home page. The compact keypad hides the card title during entry; a changed-wish warning includes the new wish name before confirmation. No wish selector, note/date editor, expression calculator, record history or animation is added. With no wish, entries remain unbound. Amounts are self-reported savings, not deposits or an account balance.

## Implementation

- Android `AppWidgetProvider` and `RemoteViews`, with `targetCellWidth`/`targetCellHeight` both 2 and a 110 × 110dp minimum/fallback. Text, buttons and keypad adapt to the smaller area. Host dimensions bound the image size, capped at 512 × 512 pixels. Existing card colors and illustrations are retained.
- `HomeWidgetBridge` publishes consistent controller snapshots and reloads when returning to the application. Language follows the existing preference. Android can delay periodic refreshes.
- Widget operations reuse an existing application controller, or a short-lived, UI-free Flutter engine running `widgetMain`. Both use `HomeWidgetService`, `RecordsController` and the existing SQLite repository. No new runtime dependency or database migration.
- Draft amount, target wish, occurrence date and request token persist before submission. An unconfirmed submission is immutable; Retry uses the same token. Repository idempotency and snapshot recovery prevent duplicate entries. If the selected wish changes, the user reviews it before saving. Separate placed widgets have separate drafts; removal does not delete saved records.
- Honor's launcher replaces framework buttons with `com.hihonor.android.widget.Button`. Its unannotated `setEnabled` override is rejected by asynchronous `RemoteViews` inflation, causing the entire widget to display an error. Submitted-state controls now remove their click PendingIntents instead of calling `setEnabled`; the receiver still rejects edits/cancellation of unconfirmed submissions. This preserves input locking without the incompatible reflection call.
- Widget acceptance builds have explicit **Wallehog Test** / **Wallehog 2x2 Test** application and provider labels. The ordinary app/provider labels are unchanged. Test data remain separate and are not automatically copied to the ordinary app.

## Verification

The loading failure was reproduced on the connected CGL-W00's actual Honor launcher. Its trace reported `Button can't use method with RemoteViews: setEnabled(boolean)`. Removing the background-resource action did not fix the error; removing the two enabled-state calls did, with background colors restored. The real launcher then displayed the 2 × 2 card and observed saved-state updates. The original same-application host test had not exercised Honor's substituted buttons.

Current checks: `flutter analyze`, eight widget-service regressions, and the final arm64 release build passed. Native `HomeWidgetTest` passed in a fresh `.widgetcompactuitest` package (`OK (1 test)`, 27.556 seconds): 2 × 2 metadata, 156 × 156dp card/keypad captures, exact SQLite deltas, retry protection, changed-wish review, cancellation, English, foreground entry and idle worker teardown. Existing `.widgetuitest` records were preserved rather than reset for the rerun.

`LauncherWidgetTest` also passed (`OK (2 tests)`): a separate application's host loads the ordinary release widget, and accessibility inspection confirms the action is inflated in the actual launcher. The latter requires opening the page containing the placed widget and passing its package using `-e placedPackage`; it makes no clicks or data writes. Debug-only package visibility enables access to the ordinary APK's resources; release permissions are unchanged.

[Card](screenshots/widget-native-card.png), [amount entry](screenshots/widget-native-entry.png), and [English entry](screenshots/widget-native-en-entry.png) are 156 × 156dp native-host captures with fictional data. Actual launcher captures containing device/user data remain local. Original display size 2032 × 3048, density 400 and font scale 1.0 were unchanged during this fix. Temporary widget-binding permissions and diagnostic log levels are restored after acceptance.

The ordinary installation was updated using `adb install -r`: `Success`. Cold startup returned `Status: ok`, `LaunchState: COLD`, with a live process. There was no uninstall, data clearing or migration. Version remains `0.5.0+5`; no release was published. Remove an old widget and choose **Wallehog**, not a **Test** provider, for the new 2 × 2 placement. Other launcher implementations have not been individually verified.
