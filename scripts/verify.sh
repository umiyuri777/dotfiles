#!/usr/bin/env bash
# install.sh を実行したあとの状態を検証する（CI でも手元でも使う）
#   scripts/verify.sh             Brewfile の内容を確認
#   scripts/verify.sh --optional  Brewfile.optional も確認
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

with_optional=false
case "${1:-}" in
  --optional) with_optional=true ;;
  "") ;;
  *) echo "usage: $0 [--optional]" >&2; exit 1 ;;
esac

failures=0
section() { printf '\n\033[1m%s\033[0m\n' "$*"; }
pass() { printf '  \033[32mok\033[0m  %s\n' "$*"; }
fail() { printf '  \033[31mNG\033[0m  %s\n' "$*"; failures=$((failures + 1)); }
indent() { sed 's/^/        /'; }

# 疑似端末の中でログインシェル + 対話シェルの zsh を起動する
# （CI には端末がなく、そのままだと zle が使えないため実際のターミナルと挙動が変わる）
zsh_tty() {
  script -q /dev/null zsh -l -i -c "$1" </dev/null 2>&1 |
    LC_ALL=C sed -e $'s/\\^D\b\b//g' -e $'s/\r$//'
}

for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [[ -x $brew ]]; then
    eval "$($brew shellenv)"
    break
  fi
done

# ------------------------------------------------------------
section "Homebrew"
brewfiles=(Brewfile)
$with_optional && brewfiles+=(Brewfile.optional)
for f in "${brewfiles[@]}"; do
  if out=$(brew bundle check --file="$DOTFILES_DIR/$f" --no-upgrade --verbose 2>&1); then
    pass "$f のパッケージがすべて入っている"
  else
    fail "$f に入っていないパッケージがある"
    echo "$out" | indent
  fi
done

# ------------------------------------------------------------
section "シンボリックリンク"
out=$("$DOTFILES_DIR/scripts/link.sh" --dry-run 2>&1)
if grep -q "すべてリンク済みです" <<<"$out"; then
  pass "home/ 以下がすべてリンクされている"
else
  fail "リンクされていないファイルがある"
  echo "$out" | indent
fi

# ------------------------------------------------------------
section "macOS の設定"
while IFS= read -r line; do
  case "$line" in
    pass:*) pass "${line#pass:}" ;;
    fail:*) fail "${line#fail:}" ;;
  esac
done < <("$DOTFILES_DIR/scripts/macos.sh" --check)

# ------------------------------------------------------------
section "zsh"
out=$(zsh_tty exit)
if [[ -z $out ]]; then
  pass "エラーや警告なしで起動する"
else
  fail "起動時にエラーや警告が出る"
  echo "$out" | indent
fi

# zsh の中で確認し、結果を "pass:..." / "fail:..." の行で返す
results=$(zsh_tty '
  # 対話シェルでプロンプトが出るたびに走るフック（mise の PATH 切り替えなど）を一度実行する
  for f in $precmd_functions; do $f; done

  for c in git gh ghq fzf rg starship mise uv pnpm tmux tree wget yq; do
    if (( $+commands[$c] )); then echo "pass:$c"; else echo "fail:$c が見つからない"; fi
  done

  typeset -A version_cmd=(node "node --version" ruby "ruby --version" python "python --version" go "go version")
  for t in node ruby python go; do
    p=$(whence -p $t)
    w=$(mise where $t 2>/dev/null)
    # PATH には ruby/3 のようなエイリアスのパスが入るので、実体のパスで比べる
    if [[ -n $p && -n $w && ${p:A} == ${w:A}/* ]]; then
      echo "pass:$t: $(eval $version_cmd[$t] 2>&1 | head -1)"
    else
      echo "fail:$t が mise のものになっていない (${p:-見つからない})"
    fi
  done

  check_key() {
    if [[ $(bindkey "$1") == *" $2" ]]; then echo "pass:$3"; else echo "fail:$3 ($(bindkey "$1"))"; fi
  }
  check_key "^[[A" history-substring-search-up   "↑ で history-substring-search"
  check_key "^[[B" history-substring-search-down "↓ で history-substring-search"
  check_key "^R"   fzf-history-widget            "Ctrl-R で fzf の履歴検索"
  check_key "^]"   ghq-fzf-cd                    "Ctrl-] で ghq のリポジトリへ移動"

  if [[ $(git config --global user.name) == umiyuri777 ]]; then
    echo "pass:git の user.name が設定されている"
  else
    echo "fail:git の user.name が設定されていない"
  fi
')

while IFS= read -r line; do
  case "$line" in
    pass:*) pass "${line#pass:}" ;;
    fail:*) fail "${line#fail:}" ;;
    *) [[ -n $line ]] && fail "想定外の出力: $line" ;;
  esac
done <<<"$results"

# ------------------------------------------------------------
echo
if [[ $failures -eq 0 ]]; then
  printf '\033[32mすべての確認に成功しました\033[0m\n'
else
  printf '\033[31m%d 件の確認に失敗しました\033[0m\n' "$failures"
  exit 1
fi
