#!/usr/bin/env bash
# Claude Code status line: model, context use, and 5-hour / 7-day usage limits.

input=$(cat)

model=$(jq -r '.model.display_name // "Claude"' <<<"$input")
ctx=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
five=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
five_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$input")
week=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
week_reset=$(jq -r '.rate_limits.seven_day.resets_at // empty' <<<"$input")

# Format an epoch timestamp (GNU date on Linux, BSD date on macOS)
fmt_time() {
  date -d "@$1" "$2" 2>/dev/null || date -r "$1" "$2"
}

reset=$'\e[0m'
dim=$'\e[2m'

# Green under 50%, yellow under 80%, red above
color_for() {
  if (($1 >= 80)); then printf '\e[31m'
  elif (($1 >= 50)); then printf '\e[33m'
  else printf '\e[32m'
  fi
}

bar() {
  local pct=${1%.*} width=10 filled i full='' empty=''
  filled=$((pct * width / 100))
  ((filled > width)) && filled=$width
  for ((i = 0; i < filled; i++)); do full+='█'; done
  for ((i = filled; i < width; i++)); do empty+='░'; done
  printf '%s%s%s%s%s %s%3d%%%s' "$(color_for "$pct")" "$full" "$dim" "$empty" "$reset" "$(color_for "$pct")" "$pct" "$reset"
}

out="$model"
[[ -n $ctx ]] && out+=" ${dim}│${reset} ctx ${ctx%.*}%"
if [[ -n $five ]]; then
  out+=" ${dim}│${reset} 5h $(bar "$five")"
  [[ -n $five_reset ]] && out+=" ${dim}↻$(fmt_time "$five_reset" '+%H:%M')${reset}"
fi
if [[ -n $week ]]; then
  out+=" ${dim}│${reset} 7d $(bar "$week")"
  [[ -n $week_reset ]] && out+=" ${dim}↻$(fmt_time "$week_reset" '+%a %H:%M')${reset}"
fi

printf '%s\n' "$out"
