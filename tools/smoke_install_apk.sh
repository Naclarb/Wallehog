#!/usr/bin/env bash
# Only run on a disposable emulator. Never uninstall the user's ordinary app.
set -euo pipefail
apk=${1:?APK path required}
package=dev.wallehog.wallehog
[[ "$(adb shell getprop ro.kernel.qemu | tr -d '\r')" == 1 ]] || {
  echo 'Installation smoke test requires a disposable emulator.' >&2
  exit 1
}
adb install "$apk"
adb shell am start -W -n "$package/.MainActivity"
sleep 5
adb shell pidof "$package"
adb shell am force-stop "$package"
adb install -r "$apk"
adb shell am start -W -n "$package/.MainActivity"
sleep 5
adb shell pidof "$package"
