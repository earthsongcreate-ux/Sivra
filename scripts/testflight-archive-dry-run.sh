#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_dir="$repo_root/apps/sivra"
archive_path="$app_dir/build/ios/archive/Runner.xcarchive"

"$repo_root/scripts/check-ios-project-security.sh"

if find "$repo_root/.git/hooks" -maxdepth 1 -type f ! -name '*.sample' -print -quit | grep -q .; then
  echo "blocked active non-sample Git hook" >&2
  exit 1
fi

cd "$app_dir"
flutter analyze
flutter test
npm --prefix functions run lint

rm -rf "$archive_path"
flutter build ipa \
  --release \
  --no-codesign \
  --dart-define=SIVRA_BUILD_CHANNEL=testflight \
  --dart-define=SIVRA_DIAGNOSTICS=false

test -d "$archive_path"
"$repo_root/scripts/check-ios-project-security.sh"

echo "unsigned TestFlight archive dry run: ok"
echo "$archive_path"
