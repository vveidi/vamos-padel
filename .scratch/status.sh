#!/usr/bin/env bash
#
# Prints the statuses of the tickets in .scratch/<feature>/issues/.
#
#   .scratch/status.sh                 every feature
#   .scratch/status.sh watch-scoring   one feature
#
# The source of truth is the ticket files themselves: the `**Status:**` line,
# the `**Blocked by:**` line and the criteria checkboxes. A ticket counts as
# ready to work on once every ticket blocking it is done.

set -eo pipefail
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

scratch="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -t 1 ]; then
  dim=$'\033[2m'; bold=$'\033[1m'; reset=$'\033[0m'
  green=$'\033[32m'; yellow=$'\033[33m'; grey=$'\033[90m'
else
  dim=''; bold=''; reset=''; green=''; yellow=''; grey=''
fi

TITLE_WIDTH=44

# Pads a string with spaces to the required width. printf counts bytes, while
# a non-ASCII character takes more than one, so we count the width ourselves.
pad() {
  local s=$1 want=$2 len=${#1} i
  printf '%s' "$s"
  for ((i = len; i < want; i++)); do printf ' '; done
}

field() { sed -n "s/^\*\*$1:\*\* *//p" "$2" | head -1; }

report_feature() {
  local dir=$1 feature
  feature=$(basename "$dir")

  local nums=() titles=() statuses=() deps=() checked=() totals=()
  local f base num title status blocked total done_n

  for f in "$dir"/issues/[0-9][0-9]-*.md; do
    [ -e "$f" ] || return 0
    base=$(basename "$f")
    num=${base%%-*}
    title=$(sed -n '1s/^# *[0-9]*: *//p' "$f")
    [ -n "$title" ] || title=${base%.md}
    status=$(field Status "$f")
    [ -n "$status" ] || status='—'
    blocked=$(field 'Blocked by' "$f")
    total=$(grep -c '^- \[' "$f" || true)
    done_n=$(grep -c '^- \[x\]' "$f" || true)

    nums+=("$num")
    titles+=("$title")
    statuses+=("$status")
    deps+=("$(printf '%s' "$blocked" | grep -oE '[0-9]{2}' | tr '\n' ' ' || true)")
    checked+=("$done_n")
    totals+=("$total")
  done

  is_done() {
    local want=$1 i
    for i in "${!nums[@]}"; do
      if [ "${nums[$i]}" = "$want" ] && [ "${statuses[$i]}" = done ]; then return 0; fi
    done
    return 1
  }

  printf '\n%s%s%s\n\n' "$bold" "$feature" "$reset"
  printf '  %s' "$dim"
  pad '#' 4; pad 'Ticket' $((TITLE_WIDTH + 2)); pad 'Blocked' 10; pad 'Criteria' 10
  printf 'Status%s\n' "$reset"

  local ready=() i d waiting state criteria depends
  for i in "${!nums[@]}"; do
    waiting=''
    for d in ${deps[$i]}; do
      is_done "$d" || waiting="$waiting$d "
    done
    waiting=${waiting% }

    case "${statuses[$i]}" in
      done)    state="${green}✅ done${reset}" ;;
      wontfix) state="${grey}🚫 wontfix${reset}" ;;
      *)
        if [ -n "$waiting" ]; then
          state="${grey}⛔ waiting on ${waiting// /, }${reset}"
        elif [ "${statuses[$i]}" = ready-for-agent ]; then
          state="${green}🟢 up for grabs${reset}"
          ready+=("${nums[$i]}")
        elif [ "${statuses[$i]}" = ready-for-human ]; then
          state="${green}🟢 for a human${reset}"
          ready+=("${nums[$i]}")
        else
          state="${yellow}🟡 ${statuses[$i]}${reset}"
        fi
        ;;
    esac

    depends=${deps[$i]% }
    depends=${depends// /, }

    criteria="${checked[$i]}/${totals[$i]}"
    [ "${totals[$i]}" != 0 ] || criteria='—'

    printf '  '
    pad "${nums[$i]}" 4
    pad "${titles[$i]:0:$TITLE_WIDTH}" $((TITLE_WIDTH + 2))
    pad "${depends:-—}" 10
    pad "$criteria" 10
    printf '%s\n' "$state"
  done

  local n_done=0
  for i in "${!nums[@]}"; do
    [ "${statuses[$i]}" != done ] || n_done=$((n_done + 1))
  done

  printf '\n  Done: %s/%s' "$n_done" "${#nums[@]}"
  if [ ${#ready[@]} -gt 0 ]; then
    printf '   Up for grabs: %s' "$(IFS=,; printf '%s' "${ready[*]}" | sed 's/,/, /g')"
  fi
  printf '\n\n'
}

if [ $# -gt 0 ]; then
  for slug in "$@"; do
    if [ -d "$scratch/$slug/issues" ]; then
      report_feature "$scratch/$slug"
    else
      printf 'No tickets: %s/%s/issues\n' "$scratch" "$slug" >&2
      exit 1
    fi
  done
else
  found=0
  for dir in "$scratch"/*/; do
    if [ -d "$dir/issues" ]; then
      report_feature "${dir%/}"
      found=1
    fi
  done
  [ "$found" = 1 ] || printf 'No feature with tickets in %s\n' "$scratch" >&2
fi
