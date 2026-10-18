#!/usr/bin/env bash
# home/ 以下のファイルを $HOME の同じ場所へシンボリックリンクする
#   scripts/link.sh      リンクを作成（既存のファイルは ~/.dotfiles_backup/<日時>/ へ退避）
#   scripts/link.sh -n   実行内容を表示するだけ（dry-run）
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="$DOTFILES_DIR/home"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"

# ファイル単位ではなくディレクトリごとリンクするもの
# （アプリが設定ファイルを置き換える形で保存するため、ファイルのリンクだと外れてしまう）
DIR_LINKS=(
  .config/karabiner
  .config/zed
)

# 新しい場所の設定より優先して読まれてしまう古い設定。見つけたら退避する
LEGACY_PATHS=(
  "Library/Application Support/com.mitchellh.ghostty/config"
  "Library/Application Support/com.mitchellh.ghostty/config.ghostty"
)

dry_run=false
case "${1:-}" in
  -n | --dry-run) dry_run=true ;;
  "") ;;
  *) echo "usage: $0 [-n|--dry-run]" >&2; exit 1 ;;
esac

changed=0
$dry_run && echo "  (dry-run: 実際には変更しません)"

run() {
  $dry_run || "$@"
}

pretty() {
  echo "${1/#"$HOME"/~}"
}

backup() {
  local target="$1"
  local rel="${target#"$HOME"/}"
  echo "  backup  $(pretty "$target") -> $(pretty "$BACKUP_DIR")/$rel"
  run mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
  run mv "$target" "$BACKUP_DIR/$rel"
}

link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    backup "$dst"
  fi
  echo "  link    $(pretty "$dst") -> ${src#"$DOTFILES_DIR"/}"
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  changed=$((changed + 1))
}

is_in_dir_link() {
  local rel="$1" dir
  for dir in "${DIR_LINKS[@]}"; do
    if [[ "$rel" == "$dir" || "$rel" == "$dir"/* ]]; then
      return 0
    fi
  done
  return 1
}

for rel in "${LEGACY_PATHS[@]}"; do
  if [[ -e "$HOME/$rel" && ! -L "$HOME/$rel" ]]; then
    backup "$HOME/$rel"
    changed=$((changed + 1))
  fi
done

for dir in "${DIR_LINKS[@]}"; do
  link "$SRC_ROOT/$dir" "$HOME/$dir"
done

while IFS= read -r -d '' src; do
  rel="${src#"$SRC_ROOT"/}"
  is_in_dir_link "$rel" && continue
  link "$src" "$HOME/$rel"
done < <(find "$SRC_ROOT" -type f ! -name .DS_Store -print0 | sort -z)

if [[ $changed -eq 0 ]]; then
  echo "  すべてリンク済みです"
fi
