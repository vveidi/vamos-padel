#!/usr/bin/env bash
#
# Печатает статусы тикетов из .scratch/<feature>/issues/.
#
#   .scratch/status.sh                 все фичи
#   .scratch/status.sh watch-scoring   одна фича
#
# Источник правды — сами файлы тикетов: строка `**Status:**`, строка
# `**Blocked by:**` и чекбоксы критериев. Тикет считается готовым к работе,
# когда все его блокирующие тикеты в статусе done.

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

# Дополняет строку пробелами до нужной ширины. printf считает байты,
# а кириллица занимает по два, поэтому ширину считаем сами.
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
  pad '#' 4; pad 'Тикет' $((TITLE_WIDTH + 2)); pad 'Зависит' 10; pad 'Критерии' 10
  printf 'Статус%s\n' "$reset"

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
          state="${grey}⛔ ждёт ${waiting// /, }${reset}"
        elif [ "${statuses[$i]}" = ready-for-agent ]; then
          state="${green}🟢 можно брать${reset}"
          ready+=("${nums[$i]}")
        elif [ "${statuses[$i]}" = ready-for-human ]; then
          state="${green}🟢 для человека${reset}"
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

  printf '\n  Готово: %s/%s' "$n_done" "${#nums[@]}"
  if [ ${#ready[@]} -gt 0 ]; then
    printf '   Можно брать: %s' "$(IFS=,; printf '%s' "${ready[*]}" | sed 's/,/, /g')"
  fi
  printf '\n\n'
}

if [ $# -gt 0 ]; then
  for slug in "$@"; do
    if [ -d "$scratch/$slug/issues" ]; then
      report_feature "$scratch/$slug"
    else
      printf 'Нет тикетов: %s/%s/issues\n' "$scratch" "$slug" >&2
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
  [ "$found" = 1 ] || printf 'Нет ни одной фичи с тикетами в %s\n' "$scratch" >&2
fi
