#!/bin/bash
# List Claude instances across all tmux panes and use fzf to switch to the selected one.

if ! command -v fzf &>/dev/null; then
  tmux display-message "fzf is not installed"
  exit 1
fi

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

list_claude_panes() {
  tmux list-panes -a -F '#{session_name}|#{window_name}|#{pane_id}|#{pane_current_path}' |
    while IFS='|' read -r sess win pane_id path; do
      state=$(tmux display -p -t "$pane_id" '#{@claude_state}' 2>/dev/null)
      [ -z "$state" ] && continue

      pane_pid=$(tmux display -p -t "$pane_id" '#{pane_pid}')
      is_claude_alive "$pane_pid" || continue

      display_path="${path/$HOME/~}"

      printf '%s:%s\t%s\t%s\t%s\n' \
        "$sess" "$win" "$state" "$display_path" "$pane_id"
    done
}

data=$(list_claude_panes)

if [ -z "$data" ]; then
  tmux display-message "No Claude instances found"
  exit 0
fi

# Align only the display columns (exclude pane_id), then rejoin with tab
# so fzf shows aligned text while pane_id stays hidden for extraction
tmp_display=$(mktemp)
tmp_panes=$(mktemp)
echo "$data" | awk -F'\t' '{print $1"|"$2"|"$3}' | column -t -s '|' > "$tmp_display"
echo "$data" | awk -F'\t' '{print $4}' > "$tmp_panes"
formatted=$(paste "$tmp_display" "$tmp_panes")
rm "$tmp_display" "$tmp_panes"

selected=$(echo "$formatted" | fzf \
  --no-preview \
  --delimiter='\t' \
  --with-nth=1 \
  --header='window | status | path' \
  --bind='j:down,k:up' \
  --layout=reverse)

if [ -n "$selected" ]; then
  pane_id=$(echo "$selected" | cut -f2)
  tmux switch-client -t "$pane_id"
fi
