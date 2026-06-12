#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
raw_dir="$repo_root/screenshots/app-store/raw"
final_dir="$repo_root/screenshots/app-store/final"

raw_files=(
  "01-today-ready.png"
  "02-onboarding-focus.png"
  "03-daily-briefing.png"
  "04-articulation-answer.png"
  "05-learning-memory.png"
  "06-weekly-recap.png"
)

final_files=(
  "01-walk-in-prepared.png"
  "02-shape-how-you-think.png"
  "03-separate-signal-from-noise.png"
  "04-speak-with-clarity.png"
  "05-dont-lose-best-ideas.png"
  "06-your-thinking-compounds.png"
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
