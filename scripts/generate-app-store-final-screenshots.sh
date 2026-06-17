#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_DIR="$ROOT_DIR/screenshots/app-store/raw"
FINAL_DIR="$ROOT_DIR/screenshots/app-store/final"
BRAND_DIR="$ROOT_DIR/screenshots/app-store/brand"
ONBOARDING_FOCUS_SOURCE="/Users/macbook/Downloads/Screenshots/New Folder With Items/ONBOARDING SCREEN 3.png"

mkdir -p "$FINAL_DIR"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required. Install it with: brew install imagemagick" >&2
  exit 1
fi

WIDTH=1290
HEIGHT=2796
BACKGROUND="#07111F"
APP_BG="#07111F"
APP_PANEL="#101B2E"
APP_PANEL_2="#0C1627"
APP_STROKE="#243149"
TEXT="#F2F0EA"
MUTED="#A6ADB8"
DIM="#737B88"
ACCENT="#B89467"
ACCENT_DARK="#7D613F"
PHONE="#030509"
PHONE_EDGE="#212631"
SHADOW="#00000080"
LOGO="$BRAND_DIR/sivra-logo-horizontal.png"

PHONE_W=1074
PHONE_H=2320
PHONE_X=$(((WIDTH - PHONE_W) / 2))
PHONE_Y=443
INNER_W=996
INNER_H=2160
INNER_X=$((PHONE_X + 39))
INNER_Y=$((PHONE_Y + 80))
SCREEN_W=962
SCREEN_H=2084
SCREEN_X=$(((INNER_W - SCREEN_W) / 2))
SCREEN_Y=57

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

caption_image() {
  local output="$1"
  local width="$2"
  local height="$3"
  local font="$4"
  local size="$5"
  local color="$6"
  local gravity="$7"
  local text="$8"

  magick -size "${width}x${height}" \
    -background none \
    -font "$font" \
    -pointsize "$size" \
    -fill "$color" \
    -gravity "$gravity" \
    "caption:$text" \
    "$output"
}

place_caption() {
  local canvas="$1"
  local text="$2"
  local x="$3"
  local y="$4"
  local w="$5"
  local h="$6"
  local font="$7"
  local size="$8"
  local color="$9"
  local gravity="${10:-NorthWest}"
  local label="$TMP_DIR/caption-$RANDOM.png"

  caption_image "$label" "$w" "$h" "$font" "$size" "$color" "$gravity" "$text"
  magick "$canvas" "$label" -geometry "+${x}+${y}" -compose over -composite "$canvas"
}

draw_chip() {
  local canvas="$1"
  local x="$2"
  local y="$3"
  local w="$4"
  local text="$5"
  local selected="${6:-false}"
  local fill="$APP_PANEL_2"
  local stroke="$APP_STROKE"
  local color="$MUTED"

  if [[ "$selected" == "true" ]]; then
    fill="$ACCENT"
    stroke="$ACCENT"
    color="#111319"
  fi

  magick "$canvas" \
    -fill "$fill" \
    -stroke "$stroke" \
    -strokewidth 1 \
    -draw "roundrectangle $x,$y $((x + w)),$((y + 34)) 17,17" \
    "$canvas"
  place_caption "$canvas" "$text" "$((x + 10))" "$((y + 8))" "$((w - 20))" 18 Arial 10 "$color" Center
}

draw_metric() {
  local canvas="$1"
  local x="$2"
  local y="$3"
  local value="$4"
  local label="$5"

  place_caption "$canvas" "$value" "$x" "$y" 72 28 Arial-Bold 21 "$TEXT" NorthWest
  place_caption "$canvas" "$label" "$x" "$((y + 28))" 88 24 Arial 10 "$MUTED" NorthWest
}

make_ritual_flow_raw() {
  local output="$1"

  magick -size 440x956 "xc:$APP_BG" \
    -fill "$APP_PANEL" -stroke "$APP_STROKE" -strokewidth 1 \
    -draw "roundrectangle 24,106 416,236 18,18" \
    -draw "roundrectangle 24,270 416,738 18,18" \
    -draw "roundrectangle 24,766 416,914 18,18" \
    -fill "$ACCENT" -stroke none \
    -draw "circle 52,337 52,343" \
    -draw "circle 52,452 52,458" \
    -draw "circle 52,567 52,573" \
    -draw "circle 52,682 52,688" \
    -stroke "$ACCENT_DARK" -strokewidth 2 \
    -draw "line 52,346 52,443" \
    -draw "line 52,461 52,558" \
    -draw "line 52,576 52,673" \
    "$output"

  place_caption "$output" "Today’s Ritual" 24 42 190 28 Arial-Bold 18 "$TEXT"
  place_caption "$output" "7 minutes to sharpen the way you think." 24 72 270 28 Arial 11 "$MUTED"
  place_caption "$output" "READY SESSION" 48 130 140 18 Arial-Bold 9 "$ACCENT"
  place_caption "$output" "Product Strategy" 48 154 190 24 Arial-Bold 20 "$TEXT"
  place_caption "$output" "A focused thinking loop for decisions, judgment, and articulation." 48 186 310 34 Arial 12 "$MUTED"
  draw_metric "$output" 310 144 "7" "Minutes"

  place_caption "$output" "2" 78 318 34 28 Arial-Bold 23 "$TEXT"
  place_caption "$output" "Briefings" 118 314 160 22 Arial-Bold 16 "$TEXT"
  place_caption "$output" "Separate signal from noise before you answer." 118 340 250 34 Arial 11 "$MUTED"

  place_caption "$output" "3" 78 433 34 28 Arial-Bold 23 "$TEXT"
  place_caption "$output" "Decisions" 118 429 160 22 Arial-Bold 16 "$TEXT"
  place_caption "$output" "Practice tradeoffs, judgment, and conviction." 118 455 250 34 Arial 11 "$MUTED"

  place_caption "$output" "1" 78 548 34 28 Arial-Bold 23 "$TEXT"
  place_caption "$output" "Articulation" 118 544 160 22 Arial-Bold 16 "$TEXT"
  place_caption "$output" "Turn your thinking into clear executive language." 118 570 250 34 Arial 11 "$MUTED"

  place_caption "$output" "∞" 74 657 40 36 Arial-Bold 28 "$TEXT"
  place_caption "$output" "Saved Insight" 118 659 170 22 Arial-Bold 16 "$TEXT"
  place_caption "$output" "Capture the idea that should compound." 118 685 250 34 Arial 11 "$MUTED"

  place_caption "$output" "TODAY’S FOCUS" 48 790 140 18 Arial-Bold 9 "$ACCENT"
  draw_chip "$output" 48 820 118 "Product Strategy" true
  draw_chip "$output" 176 820 146 "Strategic Thinking" false
  magick "$output" \
    -fill "$ACCENT" \
    -stroke none \
    -draw "roundrectangle 36,876 404,908 16,16" \
    "$TMP_DIR/ritual-button-base.png"
  place_caption "$TMP_DIR/ritual-button-base.png" "Begin Ritual" 50 886 340 18 Arial-Bold 11 "#101319" Center
  mv "$TMP_DIR/ritual-button-base.png" "$output"
}

make_onboarding_focus_raw() {
  local output="$1"

  if [[ ! -f "$ONBOARDING_FOCUS_SOURCE" ]]; then
    echo "Missing onboarding focus source: $ONBOARDING_FOCUS_SOURCE" >&2
    exit 1
  fi

  magick "$ONBOARDING_FOCUS_SOURCE" \
    -crop 805x1500+56+184 +repage \
    -resize 440x956! \
    "$output"
}

make_archive_intelligence_raw() {
  local output="$1"

  magick -size 440x956 "xc:$APP_BG" \
    -fill "$APP_PANEL" -stroke "$APP_STROKE" -strokewidth 1 \
    -draw "roundrectangle 24,116 416,254 18,18" \
    -draw "roundrectangle 24,284 416,352 18,18" \
    -draw "roundrectangle 24,398 416,510 16,16" \
    -draw "roundrectangle 24,526 416,638 16,16" \
    -draw "roundrectangle 24,654 416,766 16,16" \
    -draw "roundrectangle 24,792 416,878 16,16" \
    -fill "$APP_PANEL_2" -stroke "$APP_STROKE" \
    -draw "roundrectangle 38,298 402,322 12,12" \
    -fill "$ACCENT" -stroke none \
    -draw "circle 72,826 72,831" \
    -draw "circle 162,842 162,846" \
    -draw "circle 252,820 252,824" \
    -draw "circle 342,844 342,848" \
    -stroke "$ACCENT_DARK" -strokewidth 1 \
    -draw "line 72,828 162,844" \
    -draw "line 162,844 252,822" \
    -draw "line 252,822 342,846" \
    "$output"

  place_caption "$output" "Thinking Archive" 24 48 220 28 Arial-Bold 18 "$TEXT"
  place_caption "$output" "Archive Intelligence" 48 136 180 18 Arial-Bold 9 "$ACCENT"
  place_caption "$output" "Your thinking system," 48 158 310 24 Arial-Bold 18 "$TEXT"
  place_caption "$output" "compounding daily." 48 182 310 24 Arial-Bold 18 "$TEXT"
  draw_metric "$output" 48 218 "42" "Insights"
  draw_metric "$output" 166 218 "18" "Links"
  draw_metric "$output" 284 218 "6" "Themes"

  place_caption "$output" "Search decisions, lessons, patterns, and frameworks" 72 300 290 20 Arial 11 "$MUTED"
  place_caption "$output" "CONNECTED KNOWLEDGE" 24 368 180 18 Arial-Bold 9 "$ACCENT"

  place_caption "$output" "Sharper Judgment" 48 414 140 18 Arial-Bold 9 "$ACCENT"
  place_caption "$output" "“Reduce uncertainty first, then commit the team to one clear direction.”" 48 438 320 42 Arial-Bold 13 "$TEXT"
  place_caption "$output" "Linked to: Decision Quality · Product Strategy" 48 486 300 18 Arial 10 "$MUTED"

  place_caption "$output" "Pattern Detected" 48 542 155 18 Arial-Bold 9 "$ACCENT"
  place_caption "$output" "You make stronger calls when the tradeoff is written before the recommendation." 48 566 320 42 Arial-Bold 13 "$TEXT"
  place_caption "$output" "3 related insights · 2 rituals" 48 614 250 18 Arial 10 "$MUTED"

  place_caption "$output" "Strategic Thinking" 48 670 150 18 Arial-Bold 9 "$ACCENT"
  place_caption "$output" "“The strongest signal was customer adoption velocity, not feature volume.”" 48 694 320 42 Arial-Bold 13 "$TEXT"
  place_caption "$output" "Connected to: GTM · Risk · Timing" 48 742 250 18 Arial 10 "$MUTED"

  place_caption "$output" "INSIGHT GRAPH" 48 812 120 18 Arial-Bold 9 "$ACCENT"
  place_caption "$output" "Ideas connect into a map of how you think." 48 850 300 18 Arial 10 "$MUTED"
}

make_benefits_raw() {
  local output="$1"

  magick -size 440x956 "xc:$APP_BG" \
    -fill "$APP_PANEL" -stroke "$APP_STROKE" -strokewidth 1 \
    -draw "roundrectangle 24,110 416,252 18,18" \
    -draw "roundrectangle 24,284 416,394 16,16" \
    -draw "roundrectangle 24,422 416,532 16,16" \
    -draw "roundrectangle 24,560 416,670 16,16" \
    -fill "$APP_PANEL_2" -stroke "$APP_STROKE" \
    -draw "roundrectangle 24,704 416,792 16,16" \
    -fill none -stroke "$ACCENT" -strokewidth 1.35 \
    -draw "circle 58,339 58,351" \
    -draw "circle 58,477 58,489" \
    -draw "circle 58,615 58,627" \
    -fill none -stroke "$ACCENT" -strokewidth 1.15 \
    -draw "path 'M 51 344 L 56 349 L 66 338'" \
    -draw "path 'M 52 483 L 58 472 L 64 483 M 58 472 L 58 492'" \
    -draw "path 'M 51 613 L 66 613 M 51 622 L 62 622 M 51 631 L 58 631'" \
    -fill "$ACCENT" -stroke none \
    -draw "circle 58,748 58,751" \
    -draw "circle 72,738 72,741" \
    -draw "circle 76,760 76,763" \
    -stroke "$ACCENT" -strokewidth 1 \
    -draw "line 60,748 70,740" \
    -draw "line 61,750 74,760" \
    "$output"

  place_caption "$output" "Sivra" 24 48 120 26 Arial-Bold 18 "$TEXT"
  place_caption "$output" "Think with clarity." 48 132 310 30 Arial-Bold 24 "$TEXT"
  place_caption "$output" "Lead with confidence." 48 166 310 30 Arial-Bold 24 "$TEXT"
  place_caption "$output" "A daily ritual for sharper judgment, stronger communication, and better decisions." 48 204 315 34 Arial 12 "$MUTED"

  place_caption "$output" "Sharper Judgment" 96 312 230 24 Arial-Bold 19 "$TEXT"
  place_caption "$output" "Make better decisions under pressure." 96 344 280 30 Arial 12 "$MUTED"

  place_caption "$output" "Strategic Thinking" 96 450 250 24 Arial-Bold 19 "$TEXT"
  place_caption "$output" "See opportunities and risks sooner." 96 482 280 30 Arial 12 "$MUTED"

  place_caption "$output" "Executive Communication" 96 588 280 24 Arial-Bold 19 "$TEXT"
  place_caption "$output" "Explain complex ideas with confidence." 96 620 280 30 Arial 12 "$MUTED"

  place_caption "$output" "Compound Intelligence" 96 728 245 22 Arial-Bold 16 "$TEXT"
  place_caption "$output" "Every insight becomes part of your personal thinking system." 96 756 270 28 Arial 11 "$MUTED"

  place_caption "$output" "Walk into any room prepared." 48 850 344 30 Arial-Bold 18 "$TEXT" Center
}

make_screen() {
  local raw="$1"
  local output="$2"
  local headline="$3"
  local subheadline="$4"
  local support_line="${5:-}"

  local raw_path="$RAW_DIR/$raw"
  local output_path="$FINAL_DIR/$output"
  local headline_size=56
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

  if (( ${#headline} > 30 )); then
    headline_size=50
  fi

  magick -size "${INNER_W}x${INNER_H}" "xc:$BACKGROUND" "$screen"
  magick "$raw_path" -resize "${SCREEN_W}x${SCREEN_H}!" "$TMP_DIR/resized-screen.png"
  magick "$screen" "$TMP_DIR/resized-screen.png" \
    -geometry "+${SCREEN_X}+${SCREEN_Y}" \
    -compose over \
    -composite \
    "$screen"

  magick -size "${INNER_W}x${INNER_H}" xc:none \
    -fill white \
    -draw "roundrectangle 0,0 $((INNER_W - 1)),$((INNER_H - 1)) 66,66" \
    "$mask"
  magick "$screen" "$mask" -alpha off -compose CopyOpacity -composite "$clipped"

  magick -size "${WIDTH}x${HEIGHT}" "xc:$BACKGROUND" \
    -fill "$SHADOW" \
    -draw "roundrectangle $((PHONE_X + 16)),$((PHONE_Y + 25)) $((PHONE_X + PHONE_W + 16)),$((PHONE_Y + PHONE_H + 25)) 102,102" \
    -fill "$PHONE" \
    -stroke "$PHONE_EDGE" \
    -strokewidth 4 \
    -draw "roundrectangle $PHONE_X,$PHONE_Y $((PHONE_X + PHONE_W)),$((PHONE_Y + PHONE_H)) 102,102" \
    -stroke "$ACCENT" \
    -strokewidth 2 \
    -draw "roundrectangle $((PHONE_X + 18)),$((PHONE_Y + 18)) $((PHONE_X + PHONE_W - 18)),$((PHONE_Y + PHONE_H - 18)) 86,86" \
    "$base"

  magick "$base" "$clipped" -geometry "+${INNER_X}+${INNER_Y}" -compose over -composite "$base"

  magick "$base" \
    -fill "#05070B" \
    -stroke "#111723" \
    -strokewidth 3 \
    -draw "roundrectangle $((PHONE_X + 410)),$((PHONE_Y + 29)) $((PHONE_X + 664)),$((PHONE_Y + 94)) 37,37" \
    -fill "$ACCENT" \
    -stroke none \
    -draw "rectangle 293,372 997,378" \
    "$base"

  caption_image "$TMP_DIR/headline.png" 1152 80 Arial-Bold "$headline_size" "$TEXT" Center "$headline"
  caption_image "$TMP_DIR/subheadline.png" 1138 72 Arial 33 "$TEXT" Center "$subheadline"
  magick "$base" "$TMP_DIR/headline.png" \
    -gravity North \
    -geometry "+0+109" \
    -compose over \
    -composite \
    "$base"
  magick "$base" "$TMP_DIR/subheadline.png" \
    -gravity North \
    -geometry "+0+207" \
    -compose over \
    -composite \
    "$base"
  if [[ -n "$support_line" ]]; then
    caption_image "$TMP_DIR/support-line.png" 1138 34 Arial 25 "$TEXT" Center "$support_line"
    magick "$base" "$TMP_DIR/support-line.png" \
      -gravity North \
      -geometry "+0+260" \
      -compose over \
      -composite \
      "$base"
  fi

  magick "$LOGO" -resize "215x54>" "$logo_resized"
  magick "$logo_resized" -alpha extract "$logo_mask"
  magick -size "$(magick identify -format '%wx%h' "$logo_resized")" "xc:$ACCENT" \
    "$logo_mask" \
    -compose CopyOpacity \
    -composite \
    "$logo_tinted"

  magick "$base" "$logo_tinted" \
    -gravity North \
    -geometry "+0+302" \
    -compose over \
    -composite \
    "$output_path"

  echo "Generated $output"
}

generate_screen_1() {
  make_screen \
    "01-today-ready.png" \
    "01-walk-into-any-room-prepared.png" \
    "WALK INTO ANY ROOM PREPARED" \
    "Think clearly. Decide faster. Communicate with confidence."
}

generate_screen_2() {
  make_ritual_flow_raw "$RAW_DIR/02-daily-ritual-flow.png"
  make_screen \
    "02-daily-ritual-flow.png" \
    "02-your-daily-thinking-ritual.png" \
    "YOUR DAILY THINKING RITUAL" \
    "2 Briefings • 3 Decisions • 1 Articulation" \
    "A complete 7-minute thinking workout."
}

generate_screen_3() {
  make_onboarding_focus_raw "$RAW_DIR/03-onboarding-focus-premium.png"
  make_screen \
    "03-onboarding-focus-premium.png" \
    "03-train-the-skills-that-matter.png" \
    "TRAIN THE SKILLS THAT MATTER" \
    "Choose the thinking domains you want to sharpen."
}

generate_screen_4() {
  make_archive_intelligence_raw "$RAW_DIR/04-archive-intelligence.png"
  make_screen \
    "04-archive-intelligence.png" \
    "04-build-a-second-brain.png" \
    "BUILD A SECOND BRAIN" \
    "Turn daily thinking into lasting knowledge."
}

generate_screen_5() {
  make_screen \
    "06-weekly-recap.png" \
    "05-see-your-thinking-evolve.png" \
    "SEE YOUR THINKING EVOLVE" \
    "Discover patterns hidden in your decisions."
}

generate_screen_6() {
  make_benefits_raw "$RAW_DIR/06-benefits-transformation.png"
  make_screen \
    "06-benefits-transformation.png" \
    "06-become-the-person-people-listen-to.png" \
    "BECOME THE PERSON PEOPLE LISTEN TO" \
    "The advantage isn't more information. It's better thinking."
}

case "${1:-all}" in
  1) generate_screen_1 ;;
  2) generate_screen_2 ;;
  3) generate_screen_3 ;;
  4) generate_screen_4 ;;
  5) generate_screen_5 ;;
  6) generate_screen_6 ;;
  all)
    generate_screen_1
    generate_screen_2
    generate_screen_3
    generate_screen_4
    generate_screen_5
    generate_screen_6
    ;;
  *)
    echo "Usage: $0 [1|2|3|4|5|6|all]" >&2
    exit 1
    ;;
esac
