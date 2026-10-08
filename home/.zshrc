# ============================================================
# PATH
# ============================================================
typeset -U path PATH  # 重複を除去

export ANDROID_HOME="$HOME/Library/Android/sdk"

path=(
  $HOME/.local/bin
  ${HOMEBREW_PREFIX:-/opt/homebrew}/opt/mysql-client/bin
  $path
  $HOME/go/bin
  $HOME/development/flutter/bin
  $HOME/.pub-cache/bin
  $ANDROID_HOME/emulator
  $ANDROID_HOME/tools
  $ANDROID_HOME/tools/bin
  $ANDROID_HOME/platform-tools
)
path=(${^path}(N-/))  # 存在しないディレクトリは除外

if /usr/libexec/java_home -v 11 >/dev/null 2>&1; then
  export JAVA_HOME="$(/usr/libexec/java_home -v 11)"
fi

# コマンドの自動リハッシュ（PATHが通った新しいコマンドをすぐ認識させる）
zstyle ":completion:*:commands" rehash 1

# ============================================================
# History
# ============================================================
HISTSIZE=100000
SAVEHIST=100000
setopt hist_ignore_dups     # 直前と同じコマンドは記録しない
setopt hist_reduce_blanks   # 余分な空白を詰めて記録する

# ============================================================
# Completion / Plugins (Homebrew)
# ============================================================
if [[ -n $HOMEBREW_PREFIX ]]; then
  fpath=($HOMEBREW_PREFIX/share/zsh-completions $fpath)
  autoload -Uz compinit && compinit

  [[ -r $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

  # 入力途中の文字列で履歴を検索（↑↓ / Ctrl-P Ctrl-N）
  if [[ -r $HOMEBREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
    source $HOMEBREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh
    HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    [[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
    [[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
  fi
fi

# fzf（Ctrl-R: 履歴検索 / Ctrl-T: ファイル検索 / Alt-C: ディレクトリ移動）
# 端末がないとき（IDE がシェルの環境変数を読み込むときなど）は zle が使えずエラーになるので読み込まない
if (( $+commands[fzf] )) && [[ -o zle ]]; then
  source <(fzf --zsh)
fi

# Ctrl-] で ghq 管理下のリポジトリへ移動
if (( $+commands[ghq] && $+commands[fzf] )); then
  ghq-fzf-cd() {
    local dir
    dir=$(ghq list --full-path | fzf --prompt='repo> ' --preview 'ls -A {}')
    if [[ -n $dir ]]; then
      BUFFER="cd ${(q)dir}"
      zle accept-line
    else
      zle reset-prompt
    fi
  }
  zle -N ghq-fzf-cd
  bindkey '^]' ghq-fzf-cd
fi

# ============================================================
# Aliases
# ============================================================
# claude code setting
alias personal-claude='CLAUDE_CONFIG_DIR=~/.claude-personal claude'
export CLAUDE_CONFIG_DIR="$HOME/.claude-personal"
alias claude-work='CLAUDE_CONFIG_DIR="$HOME/.claude" claude'

# obsidian
alias obs='open -a Obsidian'

# ============================================================
# Tools
# ============================================================
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Starshipプロンプトの初期化
(( $+commands[starship] )) && eval "$(starship init zsh)"

# mise（node / ruby / python / go のバージョン管理）
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# マシン固有の設定・秘密情報は ~/.zshrc.local に書く（リポジトリには入れない）
[[ -r $HOME/.zshrc.local ]] && source $HOME/.zshrc.local
