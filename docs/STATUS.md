# Current status

[English](STATUS.md) · [简体中文](STATUS.zh-CN.md)

Updated: 2026-11-11. Release task: `codex/release-1.0`; integration target: `main`.

The approved MVP is implemented: precise amount entry, edit/delete/rebind, multiple wishes, first-wish adoption, backups, recovery, pig feedback/sound, language switching and the 2 × 2 Android widget. Unapproved animation proposals and deferred Figma synchronization are outside the 1.0 runtime scope.

All existing feature/fix branches have been reconciled in the release task, including persistent signing. The extra wish-illustration branch was explicitly reverted before integration and adds no active assets. Historical references remain; completed branches need not be deleted.

Version is `1.0.0+1000`. Static analysis and all 218 Flutter tests passed, as did 13 release-verifier regressions and the missing-credentials rejection check. Verifier coverage includes v3.1 SDK-range labels and rejection of unpinned certificates in any range. A universal release APK passed pinned-certificate and v1/v2/v3 verification. README phone previews were regenerated from the current source with fictional data, and a native widget preview was added.

Physical-device acceptance passed 6 widget/image tests, wish-binding acceptance at phone and original tablet sizes (1 test each), and cross-package inflation of the final ordinary-app widget (1 test). The ordinary installation was updated with `adb install -r` using a private compatibility-signed build from the same source: installation and cold startup succeeded, first-install timestamp and visible application data/language were unchanged. No uninstall or data clearing occurred; original display/rotation settings and temporary widget-binding access were restored. The public APK uses the separate pinned official release certificate.

Signed GitHub publication is pending the tag-triggered build and Android 16 emulator installation/startup gate. This paragraph will be replaced with publication evidence after success.

Repository audit covered 10 remote/tag refs and 341 historical text objects. No high-confidence private-key/token pattern was found. Device models, local paths and internal review links were present in development reports. Device captures, recordings, historical verification archives and promotional source are now local-only, removed from current tracking and ignored. Current public feature documents no longer include personal device details or private signing locations. Pattern scanning cannot prove the absence of every secret.

At the owner's request, AGENTS stays public, project-development commit emails remain, and old commits are preserved without history rewriting. Previously published device information can therefore still be accessed through history. No unrelated repository, parent history or discarded animation directory was read; personal application data are not committed or uploaded. A Git push transfers committed history; it does not upload every local file.
