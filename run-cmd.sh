#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$root_dir"

swift build -c release --product SpiceCmd
exec "$root_dir/.build/release/SpiceCmd" "$@"
