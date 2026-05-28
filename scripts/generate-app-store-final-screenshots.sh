#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$ROOT_DIR/screenshots/app-store/raw"
FINAL_DIR="$ROOT_DIR/screenshots/app-store/final"
BRAND_DIR="$ROOT_DIR/screenshots/app-store/brand"

mkdir -p "$FINAL_DIR"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required. Install it with: brew install imagemagick" >&2
  exit 1
fi

WIDTH=1320
HEIGHT=2868
BACKGROUND="#07111F"
TEXT="#F2F0EA"
ACCENT="#B89467"
PHONE="#030509"
PHONE_EDGE="#212631"
SHADOW="#00000080"
LOGO="$BRAND_DIR/sivra-logo-horizontal.png"

PHONE_W=1100
PHONE_H=2380
PHONE_X=$(((WIDTH - PHONE_W) / 2))
PHONE_Y=455
INNER_W=1020
INNER_H=2216
INNER_X=$((PHONE_X + 40))
INNER_Y=$((PHONE_Y + 82))
SCREEN_W=984
SCREEN_H=2138
SCREEN_X=$(((INNER_W - SCREEN_W) / 2))
SCREEN_Y=58

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

make_screen() {
  local raw="$1"
  local output="$2"
  local headline="$3"
  local subheadline="$4"

  local raw_path="$RAW_DIR/$raw"
  local output_path="$FINAL_DIR/$output"
  local screen="$TMP_DIR/screen.png"
  local mask="$TMP_DIR/mask.png"
  local clipped="$TMP_DIR/clipped.png"
  local base="$TMP_DIR/base.png"
  local logo_resized="$TMP_DIR/logo-resized.png"
  local logo_mask="$TMP_DIR/logo-mask.png"
  local logo_tinted="$TMP_DIR/logo-tinted.png"

  if [[ ! -f "$raw_path" ]]; then
    echo "Missing raw screenshot: $raw_path" >&2
    exit 1
  fi

  if [[ ! -f "$LOGO" ]]; then
    echo "Missing brand logo: $LOGO" >&2
    exit 1
  fi

  magick -size "${INNER_W}x${INNER_H}" "xc:$BACKGROUND" "$screen"
  magick "$raw_path" \
    -resize "${SCREEN_W}x${SCREEN_H}!" \
    "$TMP_DIR/resized-screen.png"
  magick "$screen" "$TMP_DIR/resized-screen.png" \
    -geometry "+${SCREEN_X}+${SCREEN_Y}" \
    -compose over \
    -composite \
    "$screen"

  magick -size "${INNER_W}x${INNER_H}" xc:none \
    -fill white \
    -draw "roundrectangle 0,0 $((INNER_W - 1)),$((INNER_H - 1)) 68,68" \
    "$mask"

  magick "$screen" "$mask" -alpha off -compose CopyOpacity -composite "$clipped"

  magick -size "${WIDTH}x${HEIGHT}" "xc:$BACKGROUND" \
    -fill "$SHADOW" \
    -draw "roundrectangle $((PHONE_X + 16)),$((PHONE_Y + 26)) $((PHONE_X + PHONE_W + 16)),$((PHONE_Y + PHONE_H + 26)) 104,104" \
    -fill "$PHONE" \
    -stroke "$PHONE_EDGE" \
    -strokewidth 4 \
    -draw "roundrectangle $PHONE_X,$PHONE_Y $((PHONE_X + PHONE_W)),$((PHONE_Y + PHONE_H)) 104,104" \
    -stroke "$ACCENT" \
    -strokewidth 2 \
    -draw "roundrectangle $((PHONE_X + 18)),$((PHONE_Y + 18)) $((PHONE_X + PHONE_W - 18)),$((PHONE_Y + PHONE_H - 18)) 88,88" \
    "$base"

  magick "$base" "$clipped" -geometry "+${INNER_X}+${INNER_Y}" -compose over -composite "$base"

  magick "$base" \
    -fill "#05070B" \
    -stroke "#111723" \
    -strokewidth 3 \
    -draw "roundrectangle $((PHONE_X + 420)),$((PHONE_Y + 30)) $((PHONE_X + 680)),$((PHONE_Y + 96)) 38,38" \
    -fill "$ACCENT" \
    -stroke none \
    -draw "rectangle 300,382 1020,388" \
    -font Arial-Bold \
    -pointsize 58 \
    -fill "$TEXT" \
    -gravity North \
    -annotate +0+130 "$headline" \
    -font Arial \
    -pointsize 34 \
    -fill "$TEXT" \
    -annotate +0+228 "$subheadline" \
    "$base"

  magick "$LOGO" -resize "220x55>" "$logo_resized"
  magick "$logo_resized" -alpha extract "$logo_mask"
  magick -size "$(magick identify -format '%wx%h' "$logo_resized")" "xc:$ACCENT" \
    "$logo_mask" \
    -compose CopyOpacity \
    -composite \
    "$logo_tinted"

  magick "$base" "$logo_tinted" \
    -gravity North \
    -geometry "+0+310" \
    -compose over \
    -composite \
    "$output_path"

  echo "Generated $output"
}

make_screen \
  "01-today-ready.png" \
  "01-build-ai-fluency-daily.png" \
  "WALK INTO ANY ROOM PREPARED" \
  "A 7-minute ritual for founders and operators who think for a living."
make_screen \
  "02-onboarding-focus.png" \
  "02-choose-your-focus.png" \
  "SHAPE HOW YOU THINK" \
  "Choose the rooms you want to become sharper in."
make_screen \
  "03-articulation-answer.png" \
  "03-practice-clear-answers.png" \
  "PRACTICE CLEAR ANSWERS" \
  "Turn AI ideas into plain executive language"
make_screen \
  "04-source-context.png" \
  "04-review-trusted-sources.png" \
  "THINK WITH BETTER SIGNAL" \
  "Confidence starts with source quality."
make_screen \
  "05-learning-memory.png" \
  "05-track-learning-memory.png" \
  "YOUR THINKING COMPOUNDS" \
  "Save the ideas worth keeping."
make_screen \
  "06-paywall.png" \
  "06-unlock-ai-packs.png" \
  "CONTINUE YOUR DAILY REHEARSAL" \
  "Personalized Daily Packs that sharpen thinking over time."
