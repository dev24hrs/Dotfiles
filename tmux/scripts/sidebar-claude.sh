#!/usr/bin/env bash
# Interactive live agent sidebar — pane-level Claude instance detection.
#   j / k (or ↑/↓)  move cursor
#   Enter / l       jump to selected Claude pane
#   q               close entire sidebar (both panes)
# Detection: pane_current_command == "claude"
# State: timer pattern (XXs / XXm XXs) in pane content → working, else idle

G=$'\033[38;2;122;154;94m'
Y=$'\033[38;2;219;188;127m'
D=$'\033[2m'
B=$'\033[1m'
X=$'\033[0m'
HOME_CUR=$'\033[H'
CLEAR_EOS=$'\033[J'

cursor=0
last_input=0
locs=()
targets=()
projs=()
states=()

printf '\033[?25l' # hide terminal cursor
trap 'printf "\033[?25h\033[2J\033[H"; exit 0' INT TERM HUP

agent_state() { # $1 = pane_id -> idle | working
  local p="$1"
  # 1st: read from Claude Code hook state file (most reliable)
  if [ -f "/tmp/agent-state-$p" ]; then
    cat "/tmp/agent-state-$p"
    return
  fi
  # 2nd: fallback to pane content scraping (timer pattern)
  if [ -n "$TMUX" ] && tmux capture-pane -t "$p" -p -S -20 2>/dev/null | grep -qE '\(([0-9]+m ?)?[0-9]+s'; then
    echo "working"
  else
    echo "idle"
  fi
}

build() {
  locs=()
  targets=()
  projs=()
  states=()
  local seen="" pane loc _ cmd title _ dir st disp proj
  while IFS='|' read -r pane loc _ cmd title _; do
    [ -z "$pane" ] && continue
    [ "$cmd" != "claude" ] && continue
    case " $seen " in *" $pane "*) continue ;; esac
    seen="$seen $pane "
    disp="${loc}"
    # Extract project basename from pane title: "claude ~/path/to/proj" → "proj"
    dir="${title#claude }"
    [ "$dir" = "$title" ] && dir="$title"
    proj="${dir##*/}"
    st=$(agent_state "$pane")
    locs+=("$disp")
    targets+=("$pane")
    projs+=("$proj")
    states+=("$st")
  done < <(tmux list-panes -a -F '#{pane_id}|#{session_name} :|#{window_name}|#{pane_current_command}|#{pane_title}|#{pane_index}' | sort -t'|' -k2)
  local n=${#locs[@]}
  [ "$cursor" -ge "$n" ] && cursor=$((n - 1))
  [ "$cursor" -lt 0 ] && cursor=0
  if [ $((SECONDS - last_input)) -ge 2 ]; then
    local active
    active=$(tmux display -p '#{pane_id}')
    local a
    for a in $(seq 0 $((n - 1))); do
      [ "${targets[$a]}" = "$active" ] && {
        cursor=$a
        break
      }
    done
  fi
}

render() {
  printf '%s%s%s AGENTS%s\033[K\n' "$HOME_CUR" "$G" "$B" "$X"
  printf '%s j/k nav · enter jump · q quit%s\033[K\n\n' "$D" "$X"
  local n=${#locs[@]} i mark col
  if [ "$n" -eq 0 ]; then
    printf '%s  (no agents)%s\033[K\n' "$D" "$X"
  else
    for i in $(seq 0 $((n - 1))); do
      case "${states[$i]}" in
      working)
        mark="working"
        col="$Y"
        ;;
      *)
        mark="idle"
        col="$G"
        ;;
      esac
      if [ "$i" -eq "$cursor" ]; then
        printf '%s%s%s %s%-7s%s %s\033[K\n' "$B" "$col" "$mark" "$X" "${locs[$i]}" "$X" "${projs[$i]}"
      else
        printf '%s%s%s %s%-7s%s %s\033[K\n' "$col" "$mark" "$X" "$D" "${locs[$i]}" "$X" "${projs[$i]}"
      fi
      printf '\033[K\n'
    done
  fi
  printf '%s' "$CLEAR_EOS"
}

close_sidebar() {
  printf '\033[?25h'
  local cur
  cur=$(tmux display -p '#{pane_id}')
  tmux list-panes -F '#{pane_id} #{@is_sidebar}' | awk '$2==1{print $1}' | while read -r p; do
    [ "$p" != "$cur" ] && tmux kill-pane -t "$p" 2>/dev/null
  done
  tmux kill-pane
  exit 0
}

build
render
while :; do
  IFS= read -rsN1 -t 1 key
  rc=$?
  if [ "$rc" -gt 128 ]; then
    build
    render
    continue
  fi # 1s timeout → refresh
  n=${#locs[@]}
  case "$key" in
  j) [ "$cursor" -lt $((n - 1)) ] && {
    cursor=$((cursor + 1))
    last_input=$SECONDS
  } ;;
  k) [ "$cursor" -gt 0 ] && {
    cursor=$((cursor - 1))
    last_input=$SECONDS
  } ;;
  l | $'\n' | $'\r')
    [ "$n" -gt 0 ] && {
      tmux switch-client -t "${targets[$cursor]}"
      build
    }
    ;;
  q) close_sidebar ;;
  $'\033') # arrow keys: ESC [ A/B
    IFS= read -rsN2 -t 0.005 seq
    case "$seq" in
    '[A') [ "$cursor" -gt 0 ] && cursor=$((cursor - 1)) ;;
    '[B') [ "$cursor" -lt $((n - 1)) ] && cursor=$((cursor + 1)) ;;
    esac
    ;;
  esac
  render
done
