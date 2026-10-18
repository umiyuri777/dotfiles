#!/usr/bin/env bash
# Mac の開発環境をセットアップする
#   ./install.sh              Homebrew → Brewfile → シンボリックリンク → mise → macOS の設定
#   ./install.sh --link-only  シンボリックリンクだけ張り直す
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }

link_only=false
for arg in "$@"; do
  case "$arg" in
    --link-only) link_only=true ;;
    -h | --help) sed -n '2,4p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

  info "brew update"
  brew update

  info "brew bundle: Brewfile"
  brew bundle --file="$DOTFILES_DIR/Brewfile" ||
    warn "Brewfile の一部のインストールに失敗しました（上のログを確認してください）"

  # 補完関数のディレクトリが group / other から書き込み可能だと、compinit が警告を出して止まる
  info "zsh の補完ディレクトリの権限を確認します"
  # compaudit は問題のあるディレクトリを見つけると終了コード 1 を返すので、それで止まらないようにする
  { zsh -c 'fpath=($HOMEBREW_PREFIX/share/zsh-completions $HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
            autoload -Uz compaudit && compaudit' 2>/dev/null || true; } |
    while IFS= read -r dir; do
      echo "  chmod g-w,o-w $dir"
      chmod g-w,o-w "$dir" || warn "$dir の権限を変更できませんでした"
    done
fi

info "シンボリックリンクを作成します"
"$DOTFILES_DIR/scripts/link.sh"

if ! $link_only; then
  info "mise install"
  (cd "$HOME" && mise install)

  info "macOS の設定を変更します"
  "$DOTFILES_DIR/scripts/macos.sh"
fi

info "完了しました。新しいシェルを開いてください: exec zsh -l"
