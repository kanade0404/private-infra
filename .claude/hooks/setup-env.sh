#!/usr/bin/env bash
# Claude Code の SessionStart から呼ばれるローカル環境セットアップ。
#
# 毎セッション実行されるため、必ず冪等に書くこと。時間のかかる処理には
# 「既に済んでいれば skip」のガードを入れる。失敗してもセッション開始を
# 妨げないよう、エラーは握りつぶして exit 0 する。
set -uo pipefail

repo="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$repo" || exit 0

# --- git hooks (lefthook) -------------------------------------------------
# lefthook 2.x は git リポジトリルートの設定しか見ないため、ルートに
# lefthook.yml がある場合のみ install する。
# フックは git の common dir に入り worktree 間で共有されるので、
# 既に入っていれば skip する。
install_lefthook() {
  [ -f "$repo/lefthook.yml" ] || return 0

  # `--git-path hooks` は worktree でも common dir 側（共有の hooks/）を返し、
  # 相対 / 絶対の正規化も git に任せられる。
  local hooks_dir
  hooks_dir="$(git rev-parse --git-path hooks 2>/dev/null)" || return 0
  [ -n "$hooks_dir" ] || return 0

  # pre-commit だけ見ていると pre-push が欠けていても skip してしまうため、
  # 両方が揃っている場合だけ install 済みとみなす。
  if [ -x "$hooks_dir/pre-commit" ] &&
    [ -x "$hooks_dir/pre-push" ] &&
    grep -qs lefthook "$hooks_dir/pre-commit" &&
    grep -qs lefthook "$hooks_dir/pre-push"; then
    return 0
  fi

  nix develop "$repo" --command lefthook install >/dev/null 2>&1 || return 0
  printf '%s\n' '{"systemMessage":"lefthook の git hooks をインストールしました"}'
}

install_lefthook

# 今後ここに環境構築を追加していく（冪等・ガード必須）。

exit 0
