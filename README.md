# dotfiles

Mac の開発環境（ツールと設定ファイル）をまとめて管理する。

## セットアップ

```sh
git clone <this repo> ~/programming/dotfiles
cd ~/programming/dotfiles
./install.sh
```

| コマンド | 内容 |
|---|---|
| `./install.sh` | Homebrew → `Brewfile` → シンボリックリンク → `mise install` |
| `./install.sh --optional` | 上に加えて `Brewfile.optional`（案件・授業用）も入れる |
| `./install.sh --link-only` | シンボリックリンクだけ張り直す |
| `scripts/link.sh -n` | リンクで何が起きるかを確認する（dry-run） |

既存のファイルは `~/.dotfiles_backup/<日時>/` に退避してからリンクする。

## 構成

- `Brewfile` … どのマシンにも入れるもの
- `Brewfile.optional` … 特定の案件・授業で使うもの
- `home/` … `$HOME` と同じ構成で置き、`scripts/link.sh` が `$HOME` の同じ場所へリンクする
  - `.config/karabiner` と `.config/zed` はアプリが設定ファイルを置き換えて保存するので、ディレクトリごとリンクする

## ランタイム

node / ruby / python / go は mise で管理する（`home/.config/mise/config.toml`）。
プロジェクトの `.nvmrc` / `.node-version` / `.ruby-version` も読む。

```sh
mise use -g node@24   # グローバルのバージョンを変える（config.toml が更新される）
mise use node@20      # プロジェクトごとに固定する（mise.toml が作られる）
```

## リポジトリに入れないもの

マシン固有の設定や秘密情報は次のファイルに書く。

- `~/.zshrc.local`
- `~/.gitconfig.local`
- `~/.ssh/config`、`~/.config/gh/hosts.yml`、`~/.aws` など
