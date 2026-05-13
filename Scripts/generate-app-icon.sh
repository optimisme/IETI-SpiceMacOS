#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
svg_path="$root_dir/Resources/AppIcon.svg"
iconset_dir="$root_dir/Resources/AppIcon.iconset"
icns_path="$root_dir/Resources/AppIcon.icns"

if [[ ! -f "$svg_path" ]]; then
  echo "Missing icon source: $svg_path" >&2
  exit 1
fi

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "rsvg-convert is required to regenerate the app icon. Install it with: brew install librsvg" >&2
  exit 1
fi

rm -rf "$iconset_dir"
mkdir -p "$iconset_dir"

rsvg-convert -w 16 -h 16 "$svg_path" -o "$iconset_dir/icon_16x16.png"
rsvg-convert -w 32 -h 32 "$svg_path" -o "$iconset_dir/icon_16x16@2x.png"
rsvg-convert -w 32 -h 32 "$svg_path" -o "$iconset_dir/icon_32x32.png"
rsvg-convert -w 64 -h 64 "$svg_path" -o "$iconset_dir/icon_32x32@2x.png"
rsvg-convert -w 128 -h 128 "$svg_path" -o "$iconset_dir/icon_128x128.png"
rsvg-convert -w 256 -h 256 "$svg_path" -o "$iconset_dir/icon_128x128@2x.png"
rsvg-convert -w 256 -h 256 "$svg_path" -o "$iconset_dir/icon_256x256.png"
rsvg-convert -w 512 -h 512 "$svg_path" -o "$iconset_dir/icon_256x256@2x.png"
rsvg-convert -w 512 -h 512 "$svg_path" -o "$iconset_dir/icon_512x512.png"
rsvg-convert -w 1024 -h 1024 "$svg_path" -o "$iconset_dir/icon_512x512@2x.png"

iconutil -c icns "$iconset_dir" -o "$icns_path"
rm -rf "$iconset_dir"

echo "$icns_path"
