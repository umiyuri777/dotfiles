# Homebrew
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x $_brew ]]; then
    eval "$($_brew shellenv)"
    break
  fi
done
unset _brew

# mise: 非対話シェル（IDE のタスク実行など）でも node / ruby などが見えるように shims を通す
# 対話シェルでは .zshrc の `mise activate` が優先される
if (( $+commands[mise] )); then
  eval "$(mise activate zsh --shims)"
fi
