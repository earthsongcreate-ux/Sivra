#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: scripts/capture-ios-screenshot.sh 01-today-ready.png" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="$repo_root/screenshots/app-store/raw"
mkdir -p "$output_dir"

xcrun simctl io booted screenshot "$output_dir/$1"
echo "Saved $output_dir/$1"
