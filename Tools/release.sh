#!/bin/bash
# Builds a signed App Store package, and optionally uploads it to App Store Connect.
#
#   Tools/release.sh           # build/export/IkiisogiTimer.ipa
#   Tools/release.sh upload    # also upload to App Store Connect (TestFlight)
#
# The team has no registered devices, so Xcode can't make the development profile
# that a normally signed archive needs. Instead: archive unsigned, ad-hoc sign with the
# entitlements (so the App Group survives), then let the export re-sign for distribution.
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHIVE=build/IkiisogiTimer.xcarchive
APP=$ARCHIVE/Products/Applications/IkiisogiTimer.app

rm -rf "$ARCHIVE" build/export
xcodebuild archive -project IkiisogiTimer.xcodeproj -scheme IkiisogiTimer \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO -quiet

codesign -f -s - --entitlements Config/IkiisogiTimerWidget.entitlements "$APP/PlugIns/IkiisogiTimerWidgetExtension.appex"
codesign -f -s - --entitlements Config/IkiisogiTimer.entitlements "$APP"

OPTIONS=Config/ExportOptions.plist
if [ "${1:-}" = upload ]; then
  OPTIONS=build/ExportOptions-upload.plist
  sed 's#<string>export</string>#<string>upload</string>#' Config/ExportOptions.plist > "$OPTIONS"
fi

xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$OPTIONS" \
  -exportPath build/export -allowProvisioningUpdates -quiet
if [ "${1:-}" = upload ]; then
  echo "Uploaded. Bump CURRENT_PROJECT_VERSION before the next upload (each build number can be uploaded only once)."
else
  echo "Exported: build/export/IkiisogiTimer.ipa"
fi
