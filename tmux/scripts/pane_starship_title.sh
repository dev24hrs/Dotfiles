#!/usr/bin/env bash
set -euo pipefail

# Args: <pane_pid> <pane_tty> <pane_title> <pane_width> <pane_path> <pane_cmd>
pid="${1:-}"
width="${2:-80}"
pane_path="${3:-$PWD}"
pane_cmd="${4:-}"
ps_line=""

# Best-effort: inherit venv/conda from the pane's process env
if [[ -n "$pid" ]]; then
  ps_line=$(ps e -p "$pid" -o command= 2>/dev/null || true)
  if [[ -n "$ps_line" ]]; then
    venv=$(printf '%s' "$ps_line" | sed -n 's/.*[[:space:]]VIRTUAL_ENV=\([^[:space:]]*\).*/\1/p' | tail -n1)
    conda_env=$(printf '%s' "$ps_line" | sed -n 's/.*[[:space:]]CONDA_DEFAULT_ENV=\([^[:space:]]*\).*/\1/p' | tail -n1)
    conda_prefix=$(printf '%s' "$ps_line" | sed -n 's/.*[[:space:]]CONDA_PREFIX=\([^[:space:]]*\).*/\1/p' | tail -n1)
    [[ -n "$venv" ]] && export VIRTUAL_ENV="$venv"
    [[ -n "$conda_env" ]] && export CONDA_DEFAULT_ENV="$conda_env"
    [[ -n "$conda_prefix" ]] && export CONDA_PREFIX="$conda_prefix"
  fi
fi

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
title=$(trim_to_width "$title" "$width")
printf '%s' "$title"
