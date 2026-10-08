export PATH="$PATH:/Users/yamaguchiyusei/development/flutter/bin"
export ANDROID_HOME=/Users/yamaguchiyusei/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH="$PATH":"$HOME/.pub-cache/bin"export JAVA_HOME=$(/usr/libexec/java_home -v 11)

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# コマンドの自動リハッシュ（PATHが通った新しいコマンドをすぐ認識させる）
zstyle ":completion:*:commands" rehash 1

# 必要な場合はコメントアウトを外してPATHを設定してください
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
# export LANG=en_US.UTF-8

# Homebrewの補完とzsh-autosuggestionsの設定
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  autoload -Uz compinit && compinit
fi

# Starshipプロンプトの初期化
eval "$(starship init zsh)"

export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# claude code setting
alias personal-claude='CLAUDE_CONFIG_DIR=~/.claude-personal claude'
export CLAUDE_CONFIG_DIR="$HOME/.claude-personal"
alias claude-work='CLAUDE_CONFIG_DIR="~/.claude" claude'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completio

# obsidian
alias obs='open -a Obsidian'
export PATH="$PATH:$(go env GOPATH)/bin"
eval "$(~/.local/bin/mise activate)"
