#!/usr/bin/env bash
# macOS の設定（defaults）を変更する
#   scripts/macos.sh          設定を書き込む
#   scripts/macos.sh --check  設定どおりになっているか確認する（verify.sh から使う）
set -euo pipefail

# ドメイン | キー | 型 | 値 | 説明
SETTINGS=(
  "com.apple.inputmethod.Kotoeri|JIMPrefPunctuationTypeKey|int|3|日本語入力の句読点を「，．」にする（0 なら「、。」）"
  "com.apple.screencapture|show-thumbnail|bool|false|スクリーンショットのサムネイルを右下に表示しない"
  # ローカルのディスクで .DS_Store を作らないようにする設定は macOS にない
  "com.apple.desktopservices|DSDontWriteNetworkStores|bool|true|ネットワークドライブに .DS_Store を作らない"
  "com.apple.desktopservices|DSDontWriteUSBStores|bool|true|USB ドライブに .DS_Store を作らない"
)

if [[ "$(uname)" != "Darwin" ]]; then
  echo "macOS 専用です" >&2
  exit 1
fi

check=false
case "${1:-}" in
  --check) check=true ;;
  "") ;;
  *) echo "usage: $0 [--check]" >&2; exit 1 ;;
esac

# defaults read は bool を 1 / 0 で返す。文字列の "True" / "yes" なども macOS は bool として扱うので揃える
normalize() {
  local type="$1" v
  v=$(echo "$2" | tr '[:upper:]' '[:lower:]')
  if [[ $type == bool ]]; then
    case "$v" in
      1 | true | yes) echo 1; return ;;
      0 | false | no) echo 0; return ;;
    esac
  fi
  echo "$2"
}

failures=0
for setting in "${SETTINGS[@]}"; do
  IFS='|' read -r domain key type value desc <<<"$setting"
  if $check; then
    actual=$(defaults read "$domain" "$key" 2>/dev/null || echo "未設定")
    if [[ "$(normalize "$type" "$actual")" == "$(normalize "$type" "$value")" ]]; then
      echo "pass:$desc"
    else
      echo "fail:$desc（現在: $actual）"
      failures=$((failures + 1))
    fi
  else
    echo "  $desc"
    defaults write "$domain" "$key" "-$type" "$value"
  fi
done

if $check; then
  [[ $failures -eq 0 ]]
  exit
fi

# 変更を反映する（.DS_Store の設定は再ログイン後に確実に反映される）
killall -HUP JapaneseIM-RomajiTyping JapaneseIM-KanaTyping 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
