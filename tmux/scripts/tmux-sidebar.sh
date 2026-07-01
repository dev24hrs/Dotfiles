#!/usr/bin/env bash
# Toggle a left-docked sidebar with two vertical panes:
#   top:    tmux session list (sidebar-sessions.sh)
#   bottom: Claude agent list  (sidebar-claude.sh)
# Both are real splits, so content reflows beside them; closing reclaims all space.

sb_panes=$(tmux list-panes -F '#{pane_id} #{@is_sidebar}' | awk '$2=="1"{print $1}')

if [ -n "$sb_panes" ]; then
  # Kill all sidebar panes
  echo "$sb_panes" | while read -r pane; do
    [ -n "$pane" ] && tmux kill-pane -t "$pane" 2>/dev/null
  done
else
  # Remember the main pane so we can return focus to it
  main_pane=$(tmux display -p '#{pane_id}')

  # Create left sidebar pane (top half: sessions)
  sb_top=$(tmux split-window -hbf -l 30 -P -F '#{pane_id}' -c "#{pane_current_path}" \
    "exec $HOME/.config/tmux/scripts/sidebar-sessions.sh")
  tmux set -p -t "$sb_top" @is_sidebar 1

  # Split vertically (default 50/50): bottom half shows agents
  sb_bottom=$(tmux split-window -v -t "$sb_top" -P -F '#{pane_id}' -c "#{pane_current_path}" \
    "exec $HOME/.config/tmux/scripts/sidebar-claude.sh")
  tmux set -p -t "$sb_bottom" @is_sidebar 1

  # Return focus to main pane
  tmux select-pane -t "$main_pane"
fi
