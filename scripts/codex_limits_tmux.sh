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

latest_primary_rate_limits="$(
  jq -c '
    select(.type == "event_msg" and .payload.type == "token_count")
    | .payload.rate_limits
    | select(.limit_id == "codex")
  ' "$latest_file" 2>/dev/null | tail -n 1
)"

latest_non_spark_rate_limits="$(
  jq -c '
    select(.type == "event_msg" and .payload.type == "token_count")
    | .payload.rate_limits
    | select((.limit_name // "" | test("spark"; "i")) | not)
  ' "$latest_file" 2>/dev/null | tail -n 1
)"

latest_any_rate_limits="$(
  jq -c '
    select(.type == "event_msg" and .payload.type == "token_count")
    | .payload.rate_limits
  ' "$latest_file" 2>/dev/null | tail -n 1
)"

selected_rate_limits="$latest_primary_rate_limits"
if [[ -z "$selected_rate_limits" ]]; then
  selected_rate_limits="$latest_non_spark_rate_limits"
fi
if [[ -z "$selected_rate_limits" ]]; then
  selected_rate_limits="$latest_any_rate_limits"
fi

if [[ -z "$selected_rate_limits" ]]; then
  printf 'codex N/A'
  exit 0
fi

primary_used="$(printf '%s' "$selected_rate_limits" | jq -r '.primary.used_percent // empty' 2>/dev/null || true)"
secondary_used="$(printf '%s' "$selected_rate_limits" | jq -r '.secondary.used_percent // empty' 2>/dev/null || true)"
secondary_resets_at="$(printf '%s' "$selected_rate_limits" | jq -r '.secondary.resets_at // empty' 2>/dev/null || true)"
credits_has_credits="$(printf '%s' "$selected_rate_limits" | jq -r '.credits.has_credits // false' 2>/dev/null || true)"
credits_unlimited="$(printf '%s' "$selected_rate_limits" | jq -r '.credits.unlimited // false' 2>/dev/null || true)"
credits_balance="$(printf '%s' "$selected_rate_limits" | jq -r '.credits.balance // empty' 2>/dev/null || true)"

if [[ -z "$primary_used" || -z "$secondary_used" ]]; then
  printf 'codex N/A'
  exit 0
fi

# API can return 0-1 or 0-100 depending on build; normalize to 0-100.
# Infer scale from current pair: if either value is >1, treat both as 0-100 scale.
normalize_pct() {
  local value="$1"
  local mode="$2"
  awk -v v="$value" -v m="$mode" 'BEGIN {
    if (m == "fraction") {
      printf("%.0f", v * 100)
    } else {
      printf("%.0f", v)
    }
  }'
}

scale_mode='percent'
if awk -v p="$primary_used" -v s="$secondary_used" 'BEGIN { exit !((p <= 1.0) && (s <= 1.0)) }'; then
  scale_mode='fraction'
fi

used5h="$(normalize_pct "$primary_used" "$scale_mode")"
usedweek="$(normalize_pct "$secondary_used" "$scale_mode")"

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

credits_text='N/A'
if [[ "$credits_unlimited" == "true" ]]; then
  credits_text='inf'
elif [[ "$credits_has_credits" == "true" && -n "$credits_balance" && "$credits_balance" != "null" ]]; then
  credits_text="$(awk -v v="$credits_balance" 'BEGIN { printf("%.0f", v) }')"
fi

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

printf '#[fg=colour255,bg=%s,bold] 5h %s%% #[default] #[fg=colour255,bg=%s,bold] week %s%% (%sd) #[default] #[fg=colour255,bg=colour240,bold] cr %s #[default]' \
  "$bg5h" "$left5h" "$bgweek" "$leftweek" "$week_days_left" "$credits_text"
