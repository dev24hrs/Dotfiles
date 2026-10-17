#!/bin/bash
# r2-upload-images.sh —— 图片上传到 Cloudflare R2，输出公网 URL
#
# 用法：
#   bash r2-upload-images.sh <图片...>   # 逐个上传，输出与输入同序的 URL
#
# 对象键：blog/<YYYY-MM-DD>-<sha256 前 16 位>.<ext>
#   例：blog/2026-10-17-9f86d081884c7d65.png
#   文件名里带内容哈希，因此无需查重/校验冲突：同一张图重复上传得到同一 URL。
# 前置：npm i -g wrangler && wrangler login，bucket 与自定义域名均已就绪
#
# 时序（与 Typora 的交互契约，决定了本脚本只能这么写）：
#   1. 粘贴/拖入图片：Typora 先把图片落成本地文件（如
#      ~/Library/Application Support/typora-user-images/image-20261017070039823.png），
#      文档里的 <img src> 此时指向本地路径，图片立即可显示。
#   2. Typora 调用本脚本，把本次待上传的图片路径全部追加为参数
#      （一次插入多张 → 一次调用带多个路径；分多次粘贴 → 分多次调用）。
#   3. 本脚本逐张上传；全部成功才把 URL 一次性写到 stdout（顺序 = 参数顺序），
#      任一失败则 stdout 保持 0 字节且退出码非 0。
#   4. 脚本退出后，Typora 读 stdout 的最后 N 行（N = 图片数）作为 URL，
#      按位置替换文档里的本地路径；失败则保留本地路径并提示错误。
#   所以：本脚本只负责“输出正确的 URL 序列”——不修改文档、不删除本地文件、
#   不做本地文件清理（本地副本由 Typora 管理，清理见 Image Tools）。

set -euo pipefail

# ── 配置 ────────────────────────────────────────────────────────────────────
# 绑定的自定义域名，末尾不带 /
R2_PUBLIC_BASE="${R2_PUBLIC_BASE:-https://images.dev24hrs.top}"
R2_PUBLIC_BASE="${R2_PUBLIC_BASE%/}"

BUCKET="blog-images"
KEY_PREFIX="blog"
CACHE_CONTROL="public, max-age=31536000, immutable"

# GUI 启动的 Typora 只有极简 PATH，不含 Homebrew；wrangler/npx 都在 /opt/homebrew/bin
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

# wrangler 的凭据放在 ${XDG_CONFIG_HOME:-$HOME/Library/Preferences}/.wrangler/ 下。
# 终端里 fish 设置了 XDG_CONFIG_HOME=~/.config，而 GUI 启动的 Typora 没有该变量，
# 两边会去不同目录找登录态；这里统一成 ~/.config（与终端里 wrangler login 一致）。
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CONFIG_HOME

# wrangler 会把“账户选择”等缓存写到 <cwd>/.wrangler/cache；Typora（GUI 启动）的
# cwd 是 /，会因 mkdir /.wrangler/cache 失败而中断上传（实测报 "Missing file or
# directory: /.wrangler/cache"）。用 WRANGLER_CACHE_DIR 固定到一个可写目录。
WRANGLER_CACHE_DIR="$HOME/.cache/wrangler"
export WRANGLER_CACHE_DIR

# 若账号下有多个 Cloudflare account，wrangler 非交互运行无法自动选择，届时启用下面这行：
# export CLOUDFLARE_ACCOUNT_ID="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# ── 工具 ────────────────────────────────────────────────────────────────────
die() {
  echo "r2-upload: $*" >&2
  exit 1
}

# 小写扩展名；无扩展名输出空串。
# 不能直接用 ${f##*.}：文件名没有点时它会把整条路径当成扩展名。
ext_of() {
  case "${1##*/}" in
  *.*) printf '%s' "${1##*.}" | tr '[:upper:]' '[:lower:]' ;;
  *) printf '' ;;
  esac
}

mime_of_ext() {
  case "$1" in
  jpg | jpeg) echo "image/jpeg" ;;
  png) echo "image/png" ;;
  gif) echo "image/gif" ;;
  webp) echo "image/webp" ;;
  avif) echo "image/avif" ;;
  svg) echo "image/svg+xml" ;;
  bmp) echo "image/bmp" ;;
  tif | tiff) echo "image/tiff" ;;
  heic | heif) echo "image/heic" ;;
  ico) echo "image/x-icon" ;;
  pdf) echo "application/pdf" ;;
  *) echo "application/octet-stream" ;;
  esac
}

# 上传单个文件；成功时向 stdout 打印公网 URL
upload_one() {
  local f="$1" ext hash key ct
  if [ ! -f "$f" ]; then
    echo "r2-upload: not a file: $f" >&2
    return 1
  fi
  ext="$(ext_of "$f")"
  case "$ext" in *[!a-z0-9]*) ext="" ;; esac # 过滤掉会把空格等带进 URL 的怪扩展名
  hash="$(shasum -a 256 "$f" | cut -c1-16)"
  key="$KEY_PREFIX/$STAMP-$hash"
  if [ -n "$ext" ]; then key="$key.$ext"; fi
  ct="$(mime_of_ext "$ext")"
  # --remote 必须保留：当前 wrangler 的 r2 object put 默认写本地
  if ! "${WRANGLER[@]}" r2 object put "$BUCKET/$key" \
    --file="$f" --content-type="$ct" --cache-control="$CACHE_CONTROL" --remote \
    >&2 </dev/null; then
    echo "r2-upload: wrangler upload failed: $f" >&2
    return 1
  fi
  printf '%s/%s\n' "$R2_PUBLIC_BASE" "$key"
}

# ── 入口 ────────────────────────────────────────────────────────────────────
[ $# -gt 0 ] || die "usage: $(basename "$0") <image...>"

case "$R2_PUBLIC_BASE" in
*REPLACE-ME*) die "set R2_PUBLIC_BASE to your R2 custom domain first" ;;
http://* | https://*) ;;
*) die "R2_PUBLIC_BASE must start with https://: $R2_PUBLIC_BASE" ;;
esac

if command -v wrangler >/dev/null 2>&1; then
  WRANGLER=(wrangler)
elif command -v npx >/dev/null 2>&1; then
  WRANGLER=(npx --yes wrangler)
else
  die "wrangler not found, install: npm i -g wrangler"
fi

STAMP="$(date +%Y-%m-%d)" # 对象键里的日期（YYYY-MM-DD）

# ── 上传：先全部上传收集 URL，全部成功后才打印 ─────────────────────────────────
# 这样任一失败时 stdout 保持 0 字节，Typora 不会把失败误当成“有 URL 可替换”。
out=""
for f in "$@"; do
  url="$(upload_one "$f")" || exit 1 # upload_one 已把原因写进 stderr
  out="$out$url"$'\n'
done

printf '%s' "$out"
