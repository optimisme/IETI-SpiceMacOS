#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

swift build

icon_svg="$root_dir/Resources/AppIcon.svg"
icon_icns="$root_dir/Resources/AppIcon.icns"
if [[ -f "$icon_svg" && ( ! -f "$icon_icns" || "$icon_svg" -nt "$icon_icns" ) ]]; then
  "$root_dir/Scripts/generate-app-icon.sh" >/dev/null
fi

app_dir="$root_dir/.build/SpiceClient.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"

rm -rf "$app_dir"
mkdir -p "$macos_dir" "$resources_dir"

cp "$root_dir/.build/debug/SpiceClient" "$macos_dir/SpiceClient"
if [[ -f "$icon_icns" ]]; then
  cp "$icon_icns" "$resources_dir/AppIcon.icns"
fi

cat > "$contents_dir/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>SpiceClient</string>
  <key>CFBundleIdentifier</key>
  <string>dev.local.SpiceClient</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>SpiceClient</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>Virt Viewer Connection File</string>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>dev.local.spiceclient.vv</string>
      </array>
      <key>CFBundleTypeExtensions</key>
      <array>
        <string>vv</string>
      </array>
    </dict>
  </array>
  <key>UTExportedTypeDeclarations</key>
  <array>
    <dict>
      <key>UTTypeIdentifier</key>
      <string>dev.local.spiceclient.vv</string>
      <key>UTTypeDescription</key>
      <string>Virt Viewer Connection File</string>
      <key>UTTypeConformsTo</key>
      <array>
        <string>public.text</string>
      </array>
      <key>UTTypeTagSpecification</key>
      <dict>
        <key>public.filename-extension</key>
        <array>
          <string>vv</string>
        </array>
      </dict>
    </dict>
  </array>
</dict>
</plist>
PLIST

echo "$app_dir"
