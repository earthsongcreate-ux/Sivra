#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
raw_dir="$repo_root/screenshots/app-store/raw"
final_dir="$repo_root/screenshots/app-store/final"

raw_files=(
  "01-today-ready.png"
  "02-onboarding-focus.png"
  "03-articulation-answer.png"
  "04-source-context.png"
  "05-learning-memory.png"
  "06-paywall.png"
)

final_files=(
  "01-build-ai-fluency-daily.png"
  "02-choose-your-focus.png"
  "03-practice-clear-answers.png"
  "04-review-trusted-sources.png"
  "05-track-learning-memory.png"
  "06-unlock-ai-packs.png"
)

missing=0

echo "Raw screenshots:"
for file in "${raw_files[@]}"; do
  if [[ -f "$raw_dir/$file" ]]; then
    echo "  ok      $file"
  else
    echo "  missing $file"
    missing=1
  fi
done

echo
echo "Final screenshots:"
for file in "${final_files[@]}"; do
  if [[ -f "$final_dir/$file" ]]; then
    echo "  ok      $file"
  else
    echo "  missing $file"
  fi
done

exit "$missing"
