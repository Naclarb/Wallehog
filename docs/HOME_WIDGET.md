# Android home-screen widget

[English](HOME_WIDGET.md) · [简体中文](HOME_WIDGET.zh-CN.md)

The **Wallehog** widget follows the current wish and uses a default **2 × 2 launcher-cell** footprint. Cell dimensions and refresh timing vary by launcher. Add it through the launcher's widget picker. Existing instances may retain their previous span; remove and add them again if necessary.

Tap **+ → enter a numeric amount → Save** directly in the widget. Tapping the title or illustration opens the application. Creating, editing and switching wishes stay in the app. With no wish, records are unbound. There is no widget calculator, note/date editor or wish selector.

Separate widgets keep separate drafts. Unconfirmed submissions are locked; retry reuses the request token to prevent duplicate records. If the selected wish changes, review the new wish before confirming. Removing a widget does not delete saved records. The language follows the application preference.

Native Android `AppWidgetProvider` / `RemoteViews` call the same Dart controller and SQLite repository as the app, using a short-lived Flutter worker when necessary. Images respect launcher dimensions, display density, a 1024px cap and the viewport bitmap-memory budget. Submitted controls remove click actions instead of using the incompatible reflected `setEnabled` call on some launchers.

Regression coverage includes numeric entry, retry/idempotency, changed wishes, cancellation, English, foreground/worker coexistence, image sizing and cross-package inflation. Native acceptance uses a separate test package with fictional data. Current results are in [STATUS](STATUS.md); device-identifying evidence is local. Other launchers have not all been individually verified.
