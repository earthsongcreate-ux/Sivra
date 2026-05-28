#!/usr/bin/env bash
set -euo pipefail

PROJECT_FILE="apps/sivra/ios/Runner.xcodeproj/project.pbxproj"

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "missing $PROJECT_FILE" >&2
  exit 1
fi

patterns=(
  "A8DAD24"
  "Provision Library Executable"
  "base64 --decode"
  "curl .*\\| sh"
  "sh -c \"\\$\\{"
  "PBXBuildRule"
)

for pattern in "${patterns[@]}"; do
  if grep -E "$pattern" "$PROJECT_FILE" >/dev/null; then
    echo "blocked suspicious iOS project marker: $pattern" >&2
    exit 1
  fi
done

echo "iOS project security markers: ok"
