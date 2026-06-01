#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_file="$repo_root/apps/sivra/ios/Runner.xcodeproj/project.pbxproj"

if [[ ! -f "$project_file" ]]; then
  echo "missing $project_file" >&2
  exit 1
fi

xcode_patterns=(
  "A8DAD24"
  "Provision Library Executable"
  "Provision Target Device"
  "base64 --decode"
  "curl .*\\| sh"
  "sh -c \"\\$\\{"
  "PBXBuildRule"
)

for pattern in "${xcode_patterns[@]}"; do
  if grep -E "$pattern" "$project_file" >/dev/null; then
    echo "blocked suspicious iOS project marker: $pattern" >&2
    exit 1
  fi
done

hook_patterns=(
  "xxd -p -r"
  "base64 --decode"
  "curl .*\\| sh"
  "sh -c"
)

while IFS= read -r hook_file; do
  for pattern in "${hook_patterns[@]}"; do
    if grep -E "$pattern" "$hook_file" >/dev/null; then
      echo "blocked suspicious Git hook marker: $hook_file: $pattern" >&2
      exit 1
    fi
  done
done < <(find "$repo_root/.git/hooks" -maxdepth 1 -type f ! -name '*.sample' -print)

echo "iOS project and Git hook security markers: ok"
