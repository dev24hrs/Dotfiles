#!/bin/bash
# cleanup-typora-images.sh —— 清理 Typora 的本地图片副本
#
# 用法：
#   bash cleanup-typora-images.sh
#
# 行为：把 ~/Library/Application Support/typora-user-images 里
#   mtime 早于“今天 00:00”的文件，移动到 ~/.Trash/typora-images-cleanup-<YYYY-MM-DD>/
#   今天（含）新建的文件保留。移动而非删除，可从废纸篓拖回。
#
# 不做引用检查
#
# 注意：Typora 不会调用本脚本，它是手动/定时清理工具，与 r2-upload-images.sh 无关。

set -uo pipefail # 不用 -e：单个文件失败不应中断整批清理

DIR="$HOME/Library/Application Support/typora-user-images"

die() {
  echo "cleanup: $*" >&2
  exit 1
}

[ $# -eq 0 ] || die "takes no arguments (it always applies now)"

# 只用 BSD 工具（stat -f / date -j），所以限定 macOS。
[ "$(uname -s)" = Darwin ] || die "macOS only (BSD stat/date)"
[ -d "$DIR" ] || die "directory not found: $DIR"

TODAY="$(date +%Y-%m-%d)"
CUTOFF="$(date -j -f "%Y-%m-%d %H:%M:%S" "$TODAY 00:00:00" "+%s" 2>/dev/null)" || die "cannot compute today's 00:00"
TRASH="$HOME/.Trash/typora-images-cleanup-$TODAY"

echo "dir:    $DIR"
echo "cutoff: mtime < $TODAY 00:00"
echo "dest:   $TRASH"

count=0
bytes=0
failed=0

while IFS= read -r -d '' f; do
  mtime="$(stat -f %m "$f" 2>/dev/null)" || continue
  [ "$mtime" -lt "$CUTOFF" ] || continue # 今天(含)之后的文件保留
  size="$(stat -f %z "$f" 2>/dev/null)"
  case "$size" in '' | *[!0-9]*) size=0 ;; esac
  count=$((count + 1))
  bytes=$((bytes + size))

  mkdir -p "$TRASH" || die "cannot create $TRASH"
  dest="$TRASH/${f##*/}"
  n=1
  while [ -e "$dest" ]; do # 同名冲突加序号，绝不覆盖
    dest="$TRASH/${f##*/}.$n"
    n=$((n + 1))
  done
  if mv -- "$f" "$dest"; then
    printf 'trashed  %s\n' "${f##*/}"
  else
    echo "cleanup: move failed: $f" >&2
    failed=$((failed + 1))
  fi
done < <(find "$DIR" -type f -print0 2>/dev/null)

human="$(awk -v b="$bytes" 'BEGIN { printf "%.1f MB", b / 1048576 }')"
printf '%s file(s), %s moved to %s\n' "$count" "$human" "$TRASH"

if [ "$failed" -ne 0 ]; then
  echo "cleanup: $failed file(s) failed" >&2
  exit 1
fi
exit 0
