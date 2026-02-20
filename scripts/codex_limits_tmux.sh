#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
SESSIONS_DIR="${CODEX_HOME_DIR}/sessions"

if ! command -v jq >/dev/null 2>&1; then
  printf 'codex N/A (jq missing)'
  exit 0
fi

if [[ ! -d "$SESSIONS_DIR" ]]; then
  printf 'codex N/A'
  exit 0
fi

latest_file="$({ find "$SESSIONS_DIR" -type f -name '*.jsonl' -print0 2>/dev/null || true; } | xargs -0 ls -t 2>/dev/null | head -n 1 || true)"

if [[ -z "${latest_file}" || ! -f "${latest_file}" ]]; then
  printf 'codex N/A'
  exit 0
fi

latest_token_count_line="$(grep '"type":"event_msg"' "$latest_file" | grep '"type":"token_count"' | tail -n 1 || true)"

if [[ -z "$latest_token_count_line" ]]; then
  printf 'codex N/A'
  exit 0
fi

primary_used="$(printf '%s' "$latest_token_count_line" | jq -r '.payload.rate_limits.primary.used_percent // empty' 2>/dev/null || true)"
secondary_used="$(printf '%s' "$latest_token_count_line" | jq -r '.payload.rate_limits.secondary.used_percent // empty' 2>/dev/null || true)"
secondary_resets_at="$(printf '%s' "$latest_token_count_line" | jq -r '.payload.rate_limits.secondary.resets_at // empty' 2>/dev/null || true)"

if [[ -z "$primary_used" || -z "$secondary_used" ]]; then
  printf 'codex N/A'
  exit 0
fi

# API can return 0-1 or 0-100 depending on build; normalize to 0-100.
normalize_pct() {
  local value="$1"
  awk -v v="$value" 'BEGIN {
    if (v <= 1.0) {
      printf("%.0f", v * 100)
    } else {
      printf("%.0f", v)
    }
  }'
}

used5h="$(normalize_pct "$primary_used")"
usedweek="$(normalize_pct "$secondary_used")"

clamp_pct() {
  local value="$1"
  if (( value < 0 )); then
    printf '0'
  elif (( value > 100 )); then
    printf '100'
  else
    printf '%s' "$value"
  fi
}

left5h="$(clamp_pct "$((100 - used5h))")"
leftweek="$(clamp_pct "$((100 - usedweek))")"

pick_bg_color_by_left() {
  local left="$1"
  if (( left <= 10 )); then
    printf 'colour196'
  elif (( left <= 25 )); then
    printf 'colour214'
  else
    printf 'colour34'
  fi
}

bg5h="$(pick_bg_color_by_left "$left5h")"
bgweek="$(pick_bg_color_by_left "$leftweek")"

week_days_left='--'
if [[ -n "${secondary_resets_at}" ]]; then
  now_epoch="$(date +%s)"
  if [[ "${secondary_resets_at}" =~ ^[0-9]+$ ]] && (( secondary_resets_at > now_epoch )); then
    week_days_left="$(awk -v now="$now_epoch" -v reset="$secondary_resets_at" 'BEGIN {
      diff = reset - now
      print int((diff + 86399) / 86400)
    }')"
  else
    week_days_left='0'
  fi
fi

printf '#[fg=colour255,bg=%s,bold] 5h %s%% #[default] #[fg=colour255,bg=%s,bold] week %s%% (%sd) #[default]' \
  "$bg5h" "$left5h" "$bgweek" "$leftweek" "$week_days_left"
