#!/usr/bin/env bash
# Interactive tmux session list sidebar (top half of the sidebar split).
#   j / k (or ↑/↓)  move cursor
#   Enter / l       switch to selected session
#   q               close entire sidebar (both panes)
# Shows session name, window count, and attached/detached status.

G=$'\033[38;2;122;154;94m'
Y=$'\033[38;2;219;188;127m'
D=$'\033[2m'
B=$'\033[1m'
X=$'\033[0m'
HOME_CUR=$'\033[H'
CLEAR_EOS=$'\033[J'

cursor=0
last_input=0
names=()
windows=()
attached=()

printf '\033[?25l'
trap 'printf "\033[?25h\033[2J\033[H"; exit 0' INT TERM HUP

build() {
  names=()
  windows=()
  attached=()
  local _ name win att
  while IFS='|' read -r name win att; do
    [ -z "$name" ] && continue
    names+=("$name")
    windows+=("$win")
    attached+=("$att")
  done < <(tmux list-sessions -F '#{session_name}|#{session_windows}|#{session_attached}')
  local n=${#names[@]}
  [ "$cursor" -ge "$n" ] && cursor=$((n - 1))
  if [ $((SECONDS - last_input)) -ge 2 ]; then
    local a
    for a in $(seq 0 $((n - 1))); do
      [ "${attached[$a]}" -gt 0 ] && {
        cursor=$a
        break
      }
    done
  fi
  [ "$cursor" -lt 0 ] && cursor=0
}

render() {
  printf '%s%s%s SESSIONS%s\n' "$HOME_CUR" "$G" "$B" "$X"
  printf '%sj/k nav · enter jump · q quit%s\n\n' "$D" "$X"
  local n=${#names[@]} i mark col
  if [ "$n" -eq 0 ]; then
    printf '%s  (no sessions)%s\n' "$D" "$X"
  else
    for i in $(seq 0 $((n - 1))); do
      if [ "${attached[$i]}" -gt 0 ]; then
        mark=">"
        col="$G"
      else
        mark=" "
        col="$Y"
      fi
      if [ "$i" -eq "$cursor" ]; then
        printf '%s%s%s %s%-7s%s (%s windows)%s\n' "$B" "$col" "$mark" "$X" "${names[$i]}" "$X" "${windows[$i]}" "$X"
      else
        printf '%s%s%s %s%-7s%s (%s windows)%s\n' "$col" "$mark" "$X" "$D" "${names[$i]}" "$X" "${windows[$i]}" "$X"
      fi
      printf '\n'
    done
  fi
  printf '%s' "$CLEAR_EOS" # clear trailing lines (no flash)
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

sleep 0.1
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
  n=${#names[@]}
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
      tmux switch-client -t "${names[$cursor]}"
      build
    }
    ;;
  q) close_sidebar ;;
  $'\033')
    IFS= read -rsN2 -t 0.005 seq
    case "$seq" in
    '[A') [ "$cursor" -gt 0 ] && cursor=$((cursor - 1)) ;;
    '[B') [ "$cursor" -lt $((n - 1)) ] && cursor=$((cursor + 1)) ;;
    esac
    ;;
  esac
  render
done
