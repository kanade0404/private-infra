# AWS/GCP モノレポ統合 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. 本計画はユーザー要望により最終的に Workflow ツールでの実行も可能。

**Goal:** `private-infra-aws`（OpenTofu/AWS）を `private-infra`（Terraform/GCP）リポジトリへ git 履歴を保ったまま `aws/` 配下に取り込み、GCP コードを `gcp/` 配下へ再配置して、実リソースに影響を与えずにモノレポ化する。

**Architecture:** バックエンド設定（TFC workspace / S3 key）を一切変更せずファイルだけを再配置する。state は物理移動しないため、各 config の `plan` が差分ゼロであることを安全ゲートとする。git subtree マージで AWS 履歴を保存し、GCP 側 CI には `gcp/**` の path filter を付与する。

**Tech Stack:** Terraform 1.11.4 (TFC remote backend) / OpenTofu 1.15.5 (S3+DynamoDB backend) / git subtree merge / GitHub Actions / Docker / Nix flake

**作業ブランチ:** `feature/monorepo-merge-aws`（作成済み）

---

## 前提条件（実行前に満たすこと）

- 検証ステップ（`plan`）には**有効なクラウド認証が必要**:
  - GCP: TFC API トークン（`TF_API_TOKEN` 相当）または `make setup` 済みの Docker コンテナ。最終検証は PR 作成時の GCP CI が自動で `terraform plan` を実行するため、ローカル認証が無くても PR で確認可能。
  - AWS: `management-admin` / `*-admin` の SSO プロファイルで `aws sso login` 済みであること（AWS は CI が無いためローカル `tofu plan` でのみ検証可能）。
- 取込元 `private-infra-aws` のデフォルトブランチは `master`（確認済み）。

---

## ファイル構成（変更マップ）

**`gcp/` へ移動する現ルートファイル:**
- `*.tf`（12 ファイル: backend.tf, gae.tf, gce.tf, gcs.tf, iam.tf, kms.tf, provider.tf, service.tf, service_account.tf, terraform.tf, variables.tf, workload_identity.tf）
- `.terraform-version`, `.terraform.lock.hcl`, `.terraformignore`, `.dockerignore`
- `Makefile`, `docker-compose.yaml`, `docker/`（ディレクトリ）
- `README.md`, `lefthook.yml`
- `CLAUDE.md`（現在ルートにある未追跡ファイル → `gcp/CLAUDE.md` へ）

**`aws/` へ subtree マージで取り込む（`private-infra-aws` のルート一式）:**
- `environments/`, `flake.nix`, `flake.lock`, `lefthook.yml`, `renovate.json`, `.envrc`, `.gitignore`, `.secretlintrc.json`, `.secretlintignore`, `.terraform.lock.hcl`, `CLAUDE.md`, `.idea/`

**ルートに残す / 新規作成:**
- 残す: `.github/`, `.gitconfig`, `.husky/`, `.idea/`, `.secretlintrc.json`, `.secretlintignore`, `renovate.json`, `docs/`
- 新規: `CLAUDE.md`（アンブレラ）, `README.md`（モノレポ入口）
- 更新: `.gitignore`（両者マージ）, `.github/workflows/plan_terraform.yaml`, `.github/workflows/apply_terraform.yaml`

---

## Task 0: ベースライン採取（安全確認）

**Files:**
- Create: `docs/superpowers/baseline/2026-06-10-state-baseline.md`（採取結果の記録）

> 目的: 統合前の各 config が「差分ゼロ」であることを記録し、統合後の比較基準にする。

- [ ] **Step 1: TFC workspace の実行モードを確認**

GCP の backend は `remote`（`gcp/backend.tf` 移動前は `backend.tf`）。Terraform Cloud の workspace `private-infra` 設定画面で以下を確認:
- Execution Mode が `Local` であること（CI が GHA 上で WIF 認証して `terraform` を実行しているため Local 想定）
- VCS 連携が有効な場合、"Terraform Working Directory" が空 or ルートであること

Expected: Local 実行モード、working-directory 依存なし。
もし Remote 実行 + working-directory 依存があれば、Task 4 後に TFC 側設定を `gcp` に更新する手順を追加する（その場合は本タスクで気づいて報告）。

- [ ] **Step 2: GCP ベースライン採取**

Run（リポジトリルートで、Docker コンテナ起動済み前提）:
```bash
docker compose exec private_infra terraform state list > /tmp/gcp-state-before.txt
docker compose exec private_infra terraform plan -no-color -input=false | tee /tmp/gcp-plan-before.txt
```
Expected: plan の末尾が `No changes. Your infrastructure matches the configuration.`

- [ ] **Step 3: AWS ベースライン採取（5 環境）**

Run（各 environment ディレクトリで、SSO ログイン済み前提。Nix env 内）:
```bash
for env in management personal-dev personal-prd business-dev business-prd; do
  ( cd /Users/kanade0404/work/private-infra-aws/environments/$env \
    && tofu state list > /tmp/aws-$env-state-before.txt \
    && tofu plan -no-color | tee /tmp/aws-$env-plan-before.txt )
done
```
Expected: 各環境とも `No changes`。

- [ ] **Step 4: 結果を記録してコミット**

`docs/superpowers/baseline/2026-06-10-state-baseline.md` に各 config の state リソース数と「No changes 確認済み」を記録。

```bash
git add docs/superpowers/baseline/2026-06-10-state-baseline.md
git commit -m "docs: capture pre-merge state baseline (all configs no-change)"
```

> ⚠️ いずれかの config で差分が出た場合、それは統合とは無関係の既存 drift。**統合作業を始める前に**ユーザーへ報告し判断を仰ぐ（統合後の差分判定をクリーンにするため）。

---

## Task 1: AWS リポジトリを履歴ごと `aws/` へ subtree マージ

**Files:**
- Create: `aws/`（`private-infra-aws` の全内容 + 履歴）

- [ ] **Step 1: リモート追加と fetch**

```bash
git remote add aws-src /Users/kanade0404/work/private-infra-aws
git fetch aws-src
```
Expected: `aws-src/master` が取得できる。

- [ ] **Step 2: unrelated histories をマージ（ツリーは未変更）**

```bash
git merge -s ours --no-commit --allow-unrelated-histories aws-src/master
```
Expected: `Automatic merge went well; stopped before committing as requested`

- [ ] **Step 3: AWS ツリーを `aws/` プレフィックスで読み込む**

```bash
git read-tree --prefix=aws/ -u aws-src/master
```
Expected: 作業ツリーに `aws/environments/...` 等が出現。

- [ ] **Step 4: コミット**

```bash
git commit -m "merge: import private-infra-aws into aws/ subtree (history preserved)"
```

- [ ] **Step 5: 取り込み確認**

```bash
git ls-files aws/ | head
git log --oneline -- aws/environments/management | head
```
Expected: `aws/environments/management/...` が存在し、AWS リポジトリ由来の過去コミットが log に出る。

- [ ] **Step 6: 一時リモートを削除**

```bash
git remote remove aws-src
```

---

## Task 2: GCP ファイルを `gcp/` へ移動

**Files:**
- Move: 上記「ファイル構成」の GCP 一式 → `gcp/`

- [ ] **Step 1: 移動先ディレクトリで git mv（追跡ファイル）**

```bash
mkdir -p gcp
git mv backend.tf gae.tf gce.tf gcs.tf iam.tf kms.tf provider.tf service.tf service_account.tf terraform.tf variables.tf workload_identity.tf gcp/
git mv .terraform-version .terraform.lock.hcl .terraformignore .dockerignore gcp/
git mv Makefile docker-compose.yaml docker README.md lefthook.yml gcp/
```
Expected: エラーなく移動。`git status` で rename として表示。

- [ ] **Step 2: 未追跡ルート CLAUDE.md を gcp/ へ移動して追跡**

```bash
mv CLAUDE.md gcp/CLAUDE.md
git add gcp/CLAUDE.md
```

- [ ] **Step 3: gcp/CLAUDE.md のパス前提を修正**

`gcp/CLAUDE.md` 内の記述を `gcp/` 配下で動く前提に更新（例: コマンド節の冒頭に「`cd gcp` で実行」を明記）。`docker compose exec private_infra …` 系コマンドはそのまま（compose ファイルが gcp/ に同梱されるため `gcp/` から実行すれば動作）。

- [ ] **Step 4: コミット**

```bash
git add -A gcp/
git commit -m "refactor: relocate GCP terraform into gcp/ (backend unchanged)"
```

- [ ] **Step 5: backend 設定が無変更であることを確認**

```bash
git show HEAD:gcp/backend.tf
```
Expected: `organization = "kaNade"` / `name = "private-infra"` が移動前と同一（差分なし、内容のみ確認）。

---

## Task 3: ルートのアンブレラ文書と共通設定を整備

**Files:**
- Create: `CLAUDE.md`（ルート/アンブレラ）
- Create: `README.md`（ルート）
- Modify: `.gitignore`

- [ ] **Step 1: ルート CLAUDE.md を作成**

`CLAUDE.md` に以下を記述（2 スタック構成の入口）:
```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 言語

ユーザーへの回答は日本語で行うこと。

## Overview

個人プロジェクト `kanade0404` のクラウドインフラを 1 リポジトリで一元管理するモノレポ。
2 つの独立したスタックを持つ:

- **`gcp/`** — GCP インフラ。Terraform 1.11.4 + Terraform Cloud (org `kaNade` / workspace `private-infra`)。Docker でツールを実行。詳細は `gcp/CLAUDE.md`。
- **`aws/`** — AWS インフラ。OpenTofu 1.15.5 + S3/DynamoDB backend、AWS Organizations マルチアカウント。Nix flake でツールを実行。詳細は `aws/CLAUDE.md`。

各スタックは backend が独立しており state は分離している。スタックを横断する共有 state は存在しない。

## 作業ディレクトリ

- GCP の作業: `cd gcp` してから `make ...`（Docker 経由）
- AWS の作業: `cd aws` してから `nix develop`（または direnv 自動有効化）、`cd environments/<env>` で `tofu ...`

## CI/CD

- GCP のみ GitHub Actions あり（`.github/workflows/`、`gcp/**` 変更時に発火）。AWS は CI なし。
```

- [ ] **Step 2: ルート README.md を作成**

```markdown
# private-infra

GCP と AWS のインフラを一元管理するモノレポ。

- `gcp/` — GCP (Terraform + Terraform Cloud)。セットアップは `cd gcp && make setup`。
- `aws/` — AWS (OpenTofu + Nix)。セットアップは `cd aws && direnv allow`。

詳細は各ディレクトリの `CLAUDE.md` を参照。
```

- [ ] **Step 3: .gitignore をマージ**

ルート `.gitignore` に AWS 側パターン（`aws/.gitignore` の内容）で不足するものを追記。少なくとも以下を含める:
```
.terraform/
**/*.tfvars
.terraform.lock.hcl の扱いは現状維持（コミット対象）
credential.json
gcp-credential.json
.terraformrc
```
（既存パターンは保持。重複は追加しない。）

- [ ] **Step 4: コミット**

```bash
git add CLAUDE.md README.md .gitignore
git commit -m "docs: add umbrella CLAUDE.md and README for monorepo"
```

---

## Task 4: GCP CI に path filter と working-directory を付与

**Files:**
- Modify: `.github/workflows/plan_terraform.yaml`
- Modify: `.github/workflows/apply_terraform.yaml`

- [ ] **Step 1: plan_terraform.yaml にトリガ path filter を追加**

`on:` ブロックを変更:
```yaml
on:
  pull_request:
    paths:
      - 'gcp/**'
      - '.github/workflows/**'
```

- [ ] **Step 2: plan_terraform.yaml の run ステップを gcp/ で実行**

`jobs.terraform.defaults` を変更:
```yaml
    defaults:
      run:
        shell: bash
        working-directory: gcp
```

- [ ] **Step 3: action-tflint の working_directory を設定**

`reviewdog/action-tflint` ステップに入力を追加:
```yaml
      - name: tflint
        uses: reviewdog/action-tflint@v1.24.2
        with:
          github_token: ${{ secrets.github_token }}
          working_directory: gcp
```

- [ ] **Step 4: apply_terraform.yaml に同様の変更を適用**

`apply_terraform.yaml` の `on:`（push trigger）に `paths: ['gcp/**', '.github/workflows/**']` を追加し、`defaults.run.working-directory: gcp` と action-tflint の `working_directory: gcp` を設定。

- [ ] **Step 5: ワークフロー構文を検証**

Run:
```bash
docker compose -f gcp/docker-compose.yaml exec private_infra ./actionlint 2>/dev/null || echo "actionlint をローカルで実行できない場合は actions.yaml の CI に委ねる"
```
Expected: actionlint がエラーを出さない（またはローカル不可なら CI 検証へ）。

- [ ] **Step 6: コミット**

```bash
git add .github/workflows/plan_terraform.yaml .github/workflows/apply_terraform.yaml
git commit -m "ci: scope GCP workflows to gcp/** and run in gcp working dir"
```

---

## Task 5: 統合後の差分ゼロ検証（安全ゲート）★最重要

**Files:** なし（検証のみ）

> backend 設定は不変なので `init` は既存 state を再認識し、`plan` は空になるはず。1 件でも差分が出たら中断。

- [ ] **Step 1: GCP を再 init して plan 検証**

Run:
```bash
docker compose -f gcp/docker-compose.yaml exec private_infra sh -c 'cd /private-cloud && terraform init -input=false && terraform state list > /tmp/gcp-state-after.txt && terraform plan -no-color -input=false | tee /tmp/gcp-plan-after.txt'
```
（compose の working_dir が gcp/ になっている前提。実態に合わせ `cd gcp && make build && make up && make plan` でも可）
Expected: `No changes`。`diff /tmp/gcp-state-before.txt /tmp/gcp-state-after.txt` が空。

- [ ] **Step 2: AWS 5 環境を再 init して plan 検証**

Run（SSO ログイン済み・Nix env 内）:
```bash
for env in management personal-dev personal-prd business-dev business-prd; do
  echo "=== $env ===" 
  ( cd aws/environments/$env \
    && tofu init -input=false \
    && tofu state list > /tmp/aws-$env-state-after.txt \
    && tofu plan -no-color | tee /tmp/aws-$env-plan-after.txt )
done
```
Expected: 各環境 `No changes`。各 `diff /tmp/aws-$env-state-before.txt /tmp/aws-$env-state-after.txt` が空。

- [ ] **Step 3: 判定**

全 6 config で plan が `No changes` かつ state list が移動前後で一致していることを確認。
- ✅ 全て差分ゼロ → Task 6 へ。
- ❌ いずれかで add/change/destroy/replace → **即中断**。原因（多くは backend 認識ミスや working-dir 誤り）を調査し、`apply` は絶対に実行しない。

---

## Task 6: PR 作成（CI による最終検証）

**Files:** なし

- [ ] **Step 1: ブランチを push**

```bash
git push -u origin feature/monorepo-merge-aws
```

- [ ] **Step 2: PR 作成**

```bash
gh pr create --title "モノレポ統合: private-infra-aws を aws/ へ取り込み、GCP を gcp/ へ再配置" --body "$(cat docs/superpowers/specs/2026-06-06-aws-gcp-monorepo-merge-design.md)"
```

- [ ] **Step 3: GCP CI の plan 結果を確認**

PR 上で `plan_terraform.yaml` が `gcp/` を対象に `tfcmt plan` を投稿する。**差分ゼロ**であることを確認（これが GCP 側のリソース無影響の最終証跡）。
Expected: tfcmt のコメントが `No changes`。

- [ ] **Step 4: マージ判断**

GCP CI が差分ゼロ、Task 5 で AWS も差分ゼロを確認済みであれば、ユーザーにマージ可否を確認。`master` への push で `apply_terraform.yaml` が走るが、差分ゼロなので GCP に変更は入らない。

---

## Self-Review（spec との突合）

- **spec §2 方針（モノレポ化のみ/ツール・backend 現状維持）** → Task 1〜4 でファイル再配置のみ。backend 改変なし（Task 2 Step 5 で確認）。✅
- **spec §3 ディレクトリ構成（gcp/ + aws/ 対称）** → Task 1（aws/）+ Task 2（gcp/）。✅
- **spec §4 取込手順（履歴保存 subtree）** → Task 1。✅
- **spec §5 state 安全移行（移動前後 plan 差分ゼロ）** → Task 0（前）+ Task 5（後）+ Task 6（CI）。✅
- **spec §5 実行前チェック（TFC working-dir 依存）** → Task 0 Step 1。✅
- **spec §6 CI path filter + working-directory** → Task 4。✅
- **spec §7 dev環境/ドキュメント併存** → Task 3（アンブレラ CLAUDE.md/README）。✅
- **spec §9 スコープ外** → backend 統合・ツール統一・AWS CI 新設は計画に含めない。✅

プレースホルダなし。型/コマンド整合（`working-directory: gcp`, backend 不変, ブランチ `feature/monorepo-merge-aws`）一貫。
