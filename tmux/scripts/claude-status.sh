#!/bin/bash
# Usage: tmux-status.sh "<label>"
# Writes Claude's current state onto the tmux pane (read by claude_picker.sh).
# Not surfaced in window-status or pane-border — picker-only by design.

[ -z "$TMUX_PANE" ] && exit 0 # not running inside tmux, nothing to do

tmux set-option -p -t "$TMUX_PANE" @claude_state "$1" 2>/dev/null
tmux set-option -p -t "$TMUX_PANE" @claude_state_at "$(date +%s)" 2>/dev/null

exit 0
