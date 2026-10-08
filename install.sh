#!/usr/bin/env bash
# Mac の開発環境をセットアップする
#   ./install.sh              Homebrew → Brewfile → シンボリックリンク → mise
#   ./install.sh --optional   Brewfile.optional も入れる
#   ./install.sh --link-only  シンボリックリンクだけ張り直す
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }

with_optional=false
link_only=false
for arg in "$@"; do
  case "$arg" in
    --optional) with_optional=true ;;
    --link-only) link_only=true ;;
    -h | --help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) warn "不明なオプション: $arg"; exit 1 ;;
  esac
done

if [[ "$(uname)" != "Darwin" ]]; then
  warn "macOS 専用です"
  exit 1
fi

if ! $link_only; then
  if ! xcode-select -p >/dev/null 2>&1; then
    info "Xcode Command Line Tools をインストールします"
    xcode-select --install
    warn "インストールが終わったら、もう一度 ./install.sh を実行してください"
    exit 1
  fi

  if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
    info "Homebrew をインストールします"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x $brew ]]; then
      eval "$($brew shellenv)"
      break
    fi
  done

  info "brew bundle: Brewfile"
  brew bundle --file="$DOTFILES_DIR/Brewfile" ||
    warn "Brewfile の一部のインストールに失敗しました（上のログを確認してください）"

  if $with_optional; then
    info "brew bundle: Brewfile.optional"
    brew bundle --file="$DOTFILES_DIR/Brewfile.optional" ||
      warn "Brewfile.optional の一部のインストールに失敗しました（上のログを確認してください）"
  fi
fi

info "シンボリックリンクを作成します"
"$DOTFILES_DIR/scripts/link.sh"

if ! $link_only; then
  info "mise install"
  (cd "$HOME" && mise install)
fi

info "完了しました。新しいシェルを開いてください: exec zsh -l"
