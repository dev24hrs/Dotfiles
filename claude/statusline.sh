#!/bin/bash
# Claude Code status line — single line, utility-first
input=$(cat)

# ── Defaults (shellcheck can't trace through eval below) ──────────────────────
DURATION_MS=0 ADDED=0 REMOVED=0 PCT=0 CTX_SIZE=0
AGENT="" WORKTREE="" STYLE="" SESSION_PCT="" SESSION_RESET="" WEEK_PCT="" WEEK_RESET=""

# ── Extract fields (single jq call for speed) ────────────────────────────────
eval "$(echo "$input" | jq -r '
  "MODEL=" + ((.model.display_name // "?") | @sh),
  "DIR=" + ((.workspace.current_dir // "?") | @sh),
  "DURATION_MS=" + ((.cost.total_duration_ms // 0) | tostring),
  "ADDED=" + ((.cost.total_lines_added // 0) | tostring),
  "REMOVED=" + ((.cost.total_lines_removed // 0) | tostring),
  "PCT=" + (((.context_window.used_percentage // 0) | floor) | tostring),
  "CTX_SIZE=" + ((.context_window.context_window_size // 0) | tostring),
  "AGENT=" + ((.agent.name // "") | @sh),
  "WORKTREE=" + ((.worktree.name // "") | @sh),
  "SESSION_PCT=" + (if .rate_limits.five_hour.used_percentage then ((.rate_limits.five_hour.used_percentage | floor) | tostring) else "" end),
  "SESSION_RESET=" + ((.rate_limits.five_hour.resets_at // "") | @sh),
  "WEEK_PCT=" + (if .rate_limits.seven_day.used_percentage then ((.rate_limits.seven_day.used_percentage | floor) | tostring) else "" end),
  "WEEK_RESET=" + ((.rate_limits.seven_day.resets_at // "") | @sh),
  "STYLE=" + ((.output_style.name // "") | @sh)
')"

# ── Derived values ────────────────────────────────────────────────────────────
DIR_SHORT="${DIR##*/}"
DURATION_S=$((DURATION_MS / 1000))
MINUTES=$((DURATION_S / 60))
SECONDS=$((DURATION_S % 60))

if [ "$CTX_SIZE" -ge 1000000 ]; then
  CTX_LABEL="$((CTX_SIZE / 1000000))M"
else
  CTX_LABEL="$((CTX_SIZE / 1000))k"
fi

if [ "$MINUTES" -gt 0 ]; then
  TIME="${MINUTES}m${SECONDS}s"
else
  TIME="${SECONDS}s"
fi

# ── Colors ────────────────────────────────────────────────────────────────────
R='\033[0m'
D='\033[2m'
B='\033[1m'
GRN='\033[32m'
YEL='\033[33m'
RED='\033[31m'
CYN='\033[36m'
MAG='\033[35m'
BLU='\033[34m'

if [ "$PCT" -lt 50 ]; then
  PC="$GRN"
elif [ "$PCT" -lt 75 ]; then
  PC="$YEL"
else PC="$RED"; fi

# ── Rate limits (5h session + 7d weekly) ──────────────────────────────────────
pct_color() {
  if [ "$1" -lt 50 ]; then
    printf '%s' "$GRN"
  elif [ "$1" -lt 75 ]; then
    printf '%s' "$YEL"
  else printf '%s' "$RED"; fi
}

# 8-cell bar, filled proportionally to percent (0-100)
bar() {
  local pct=$1 len=8 filled i out=""
  filled=$(((pct * len + 50) / 100))
  [ "$filled" -gt "$len" ] && filled=$len
  [ "$filled" -lt 0 ] && filled=0
  for ((i = 0; i < filled; i++)); do out="${out}▰"; done
  for ((i = filled; i < len; i++)); do out="${out}▱"; done
  printf '%s' "$out"
}

# Compact duration from seconds: 42m · 2h18m · 4d12h
dur_until() {
  local target=$1 now s
  now=$(date +%s)
  s=$((target - now))
  if [ "$s" -le 0 ]; then
    printf 'now'
  elif [ "$s" -lt 3600 ]; then
    printf '%dm' $((s / 60))
  elif [ "$s" -lt 86400 ]; then
    printf '%dh%02dm' $((s / 3600)) $(((s % 3600) / 60))
  else
    printf '%dd%02dh' $((s / 86400)) $(((s % 86400) / 3600))
  fi
}

LIMITS=""
if [ -n "$SESSION_PCT" ]; then
  SC=$(pct_color "$SESSION_PCT")
  SB=$(bar "$SESSION_PCT")
  if [ -n "$SESSION_RESET" ]; then
    LIMITS="${D}5h${R} ${SC}${SB}${R}  ${D}$(dur_until "$SESSION_RESET")${R}"
  else
    LIMITS="${D}5h${R} ${SC}${SB}${R}"
  fi
fi
if [ -n "$WEEK_PCT" ]; then
  WC=$(pct_color "$WEEK_PCT")
  WB=$(bar "$WEEK_PCT")
  if [ -n "$WEEK_RESET" ]; then
    WSEG="${D}7d${R} ${WC}${WB}${R}  ${D}$(dur_until "$WEEK_RESET")${R}"
  else
    WSEG="${D}7d${R} ${WC}${WB}${R}"
  fi
  [ -n "$LIMITS" ] && LIMITS="${LIMITS}  ${WSEG}" || LIMITS="$WSEG"
fi

# ── Auth identity (cached daily from ~/.claude.json) ──────────────────────────
IDENT_CACHE="$HOME/.claude/.statusline-identity"
IDENT_MAX_AGE=86400
IDENT_AGE=$IDENT_MAX_AGE
if [ -f "$IDENT_CACHE" ]; then
  IDENT_MTIME=$(stat -f %m "$IDENT_CACHE" 2>/dev/null || echo 0)
  IDENT_AGE=$(($(date +%s) - IDENT_MTIME))
fi
if [ "$IDENT_AGE" -ge "$IDENT_MAX_AGE" ] && [ -f "$HOME/.claude.json" ]; then
  jq -r '.oauthAccount.emailAddress // .oauthAccount.displayName // ""' "$HOME/.claude.json" 2>/dev/null >"$IDENT_CACHE"
fi
USER_RAW=$(cat "$IDENT_CACHE" 2>/dev/null)

# Elide email for shoulder-surfers: jason.vertrees@venlink.com → jas…@ven…k.com
elide_email() {
  local s=$1 local_part domain
  case "$s" in
  *@*)
    local_part="${s%@*}"
    domain="${s#*@}"
    [ ${#local_part} -gt 3 ] && local_part="${local_part:0:3}…"
    [ ${#domain} -gt 8 ] && domain="${domain:0:3}…${domain: -5}"
    printf '%s@%s' "$local_part" "$domain"
    ;;
  *)
    printf '%s' "$s"
    ;;
  esac
}
USER_NAME=$(elide_email "$USER_RAW")

# ── Git branch ────────────────────────────────────────────────────────────────
BRANCH=$(git -C "$DIR" symbolic-ref --short HEAD 2>/dev/null)
GIT=""
if [ -n "$BRANCH" ]; then
  DIRTY=""
  git -C "$DIR" diff --quiet HEAD 2>/dev/null || DIRTY="${YEL}*${R}"
  GIT=" ${MAG}${BRANCH}${DIRTY}"
fi

# ── Badges ────────────────────────────────────────────────────────────────────
BADGES=""
[ -n "$AGENT" ] && BADGES="${BADGES} ${CYN}[${AGENT}]${R}"
[ -n "$WORKTREE" ] && BADGES="${BADGES} ${BLU}[wt:${WORKTREE}]${R}"
if [ -n "$STYLE" ] && [ "$STYLE" != "default" ]; then
  BADGES="${BADGES} ${MAG}[${STYLE}]${R}"
fi

# ── Single line output ────────────────────────────────────────────────────────
LIMITS_SEG=""
[ -n "$LIMITS" ] && LIMITS_SEG=" ${D}│${R} ${LIMITS}"
USER_SEG=""
[ -n "$USER_NAME" ] && USER_SEG=" ${D}${USER_NAME}${R}"
echo -e "${B}${MODEL}${R}${USER_SEG} ${D}│${R} ${DIR_SHORT}${GIT}${BADGES} ${D}│${R} ${PC}${PCT}%${R}${D}/${R}${CTX_LABEL}${LIMITS_SEG} ${D}│${R} ${GRN}+${ADDED}${R}${D}/${R}${RED}-${REMOVED}${R} ${D}│${R} ${D}${TIME}${R}"
