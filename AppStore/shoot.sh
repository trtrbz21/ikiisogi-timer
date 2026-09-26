#!/bin/bash
# Captures App Store screenshots of the app screen on the 6.9" simulator.
# Usage: AppStore/shoot.sh <lang: ja|en> <name> <appearance: light|dark|navy> <unit: minutes|seconds>
set -euo pipefail
DEVICE=${DEVICE:-AAEA927B-3D37-40A4-BF6F-396B1A9FC9E4}   # iPhone 18 Pro Max
LANG_CODE=$1; NAME=$2; APPEARANCE=$3; UNIT=$4
OUT="$(dirname "$0")/screenshots/$LANG_CODE/$NAME.png"
LOCALE=$([ "$LANG_CODE" = ja ] && echo ja_JP || echo en_US)

# Keep the status bar clock consistent with the countdown shown in the app.
xcrun simctl status_bar "$DEVICE" override --time "$(date +%-H:%M)" --batteryState discharging --batteryLevel 100 --wifiBars 3 --cellularMode active --cellularBars 4
xcrun simctl ui "$DEVICE" appearance "$([ "$APPEARANCE" = light ] && echo light || echo dark)"
xcrun simctl terminate "$DEVICE" com.trtrbz21.IkiisogiTimer 2>/dev/null || true
xcrun simctl launch "$DEVICE" com.trtrbz21.IkiisogiTimer \
  -AppleLanguages "($LANG_CODE)" -AppleLocale "$LOCALE" \
  -settings.appearance "$APPEARANCE" -settings.displayUnit "$UNIT" >/dev/null
sleep 3
xcrun simctl io "$DEVICE" screenshot "$OUT" >/dev/null 2>&1
echo "$OUT"
