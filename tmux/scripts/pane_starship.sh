#!/usr/bin/env bash
set -euo pipefail

# Args: <pane_pid> <pane_width> <pane_path> <pane_cmd> <pane_id>
pid="${1:-}"
width="${2:-80}"
pane_path="${3:-$PWD}"
pane_cmd="${4:-}"
pane_id="${5:-}"

# Check if a "claude" process exists in the process tree rooted at $1
is_claude_alive() {
  local pane_pid=$1 cpid child ppid
  for cpid in $(ps -eo pid,comm | awk '$2 == "claude" {print $1}'); do
    child=$cpid
    while [ "$child" -gt 1 ] 2>/dev/null; do
      [ "$child" = "$pane_pid" ] && return 0
      ppid=$(ps -o ppid= -p "$child" 2>/dev/null | tr -d ' ')
      [ -z "$ppid" ] && break
      child=$ppid
    done
  done
  return 1
}

strip_wrappers() {
  # 1) strip ANSI CSI sequences, 2) strip bash \[\] and zsh %{ %} markers
  # (pure sed, no perl dependency — works identically on macOS BSD sed and GNU sed)
  local esc=$'\033'
  sed -E "s/${esc}\[[0-9;]*[[:alpha:]]//g" | sed -E 's/\\\[|\\\]//g; s/%\{|%\}//g'
}

run_starship() {
  local prompt_width cfg
  prompt_width="${1:-$width}"
  cfg="${STARSHIP_TMUX_CONFIG:-$HOME/.config/tmux/scripts/starship-tmux.toml}"
  STARSHIP_LOG=error STARSHIP_CONFIG="$cfg" \
    starship prompt --terminal-width "$prompt_width" | strip_wrappers | tr -d '\n'
}

trim_to_width() {
  local text max
  text="$1"
  max="$2"
  if ((${#text} <= max)); then
    printf '%s' "$text"
    return
  fi
  if ((max <= 1)); then
    printf ''
    return
  fi
  printf '%s…' "${text:0:$((max - 1))}"
}

fallback() {
  # <cmd> — <last dir>
  local last_dir
  last_dir="${pane_path##*/}"
  printf '%s — %s' "$pane_cmd" "$last_dir"
}

if command -v starship >/dev/null 2>&1; then
  title=$(cd "$pane_path" && run_starship) || title=$(fallback)
else
  title=$(fallback)
fi

# ── Claude status prefix ──────────────────────────────────────────
if [[ -n "$pane_id" ]] && [[ -n "$pid" ]]; then
  claude_state=$(tmux display -p -t "$pane_id" '#{@claude_state}' 2>/dev/null || true)
  if [[ -n "$claude_state" ]]; then
    if is_claude_alive "$pid"; then
      title="[${claude_state}] ${title}"
    else
      # Claude process gone — clear stale state
      tmux set-option -p -t "$pane_id" -u @claude_state 2>/dev/null || true
      tmux set-option -p -t "$pane_id" -u @claude_state_at 2>/dev/null || true
    fi
  fi
fi

title=$(trim_to_width "$title" "$width")
printf '%s' "$title"
