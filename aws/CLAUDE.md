# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 言語

日本語で回答すること。

## Overview

AWS infrastructure managed with OpenTofu (Terraform 互換)。Region: ap-northeast-1。Multi-account structure using AWS Organizations with IAM Identity Center (SSO) for authentication。

### ディレクトリ構成

```text
environments/
├── management/        # 管理アカウント（Organizations, SSO, state bucket）
├── personal-dev/      # 個人プロジェクト 開発環境
├── personal-prd/      # 個人プロジェクト 本番環境
├── business-dev/      # 個人事業 開発環境
└── business-prd/      # 個人事業 本番環境
```

各ディレクトリは独立した Terraform root module。State は 5 環境すべて管理アカウントの S3 バケット（key: `<環境名>/terraform.tfstate`）に保存。バケットと DynamoDB ロックテーブル自体は `management/state.tf` で管理しており、management 自身の state も同じバケットに入る自己参照的なブートストラップ構成。

### バケット/ロックテーブル喪失時の復旧（ブートストラップ）

state の保存先（S3 `private-infra-aws-tfstate` / DynamoDB `terraform-lock`）を `management/state.tf` 自身が管理しているため、これらを失うと通常の `tofu init` が通らない。喪失範囲ごとに手順が異なる。

**state オブジェクトだけを失った場合（まずこれを試す）**: バケットはバージョニング有効（`aws_s3_bucket_versioning.tfstate`）なので旧バージョンから復元できる。削除マーカーが付いただけなら、そのマーカーを `aws s3api delete-object --version-id <削除マーカーの id>` で消すだけでよい。実体を取り出して書き戻す場合は以下。

```sh
aws s3api list-object-versions --bucket private-infra-aws-tfstate \
  --prefix "<環境名>/terraform.tfstate" --profile management-admin
aws s3api get-object --bucket private-infra-aws-tfstate \
  --key "<環境名>/terraform.tfstate" --version-id <id> \
  --profile management-admin /tmp/terraform.tfstate
aws s3api put-object --bucket private-infra-aws-tfstate \
  --key "<環境名>/terraform.tfstate" --body /tmp/terraform.tfstate \
  --profile management-admin
```

**バケット自体を失った場合**:

1. 作業ディレクトリに古い `terraform.tfstate` / `terraform.tfstate.backup` が残っていれば別名へ退避する（空の local state から始めるため）
2. `management/backend.tf` を一時的にコメントアウトし、`tofu init -reconfigure` で local backend にする（既存 state の移行は走らせない）
3. `tofu apply -target=aws_s3_bucket.tfstate -target=aws_s3_bucket_versioning.tfstate -target=aws_s3_bucket_server_side_encryption_configuration.tfstate -target=aws_s3_bucket_public_access_block.tfstate -target=aws_dynamodb_table.terraform_lock` でバケットとロックテーブルを再作成
4. 残っている既存リソース（Organizations / SSO 等）は `tofu import` で local state に取り込む。ローカルバックアップがあれば import の代わりにそれを使う
5. `backend.tf` のコメントアウトを戻し、`tofu init -migrate-state` で local → S3 へ移行。移行後に `tofu state pull` で別途バックアップを取り、`tofu plan -detailed-exitcode` が 0（差分なし）になることを確認してからローカルの `terraform.tfstate` / `terraform.tfstate.backup` を削除する
6. 他 4 環境の state も同じバケットにあるため、各環境でバックアップから `tofu state push`（無ければ同様に import）して復旧する

**ロックテーブルだけを失った場合**: state 本体は S3 にあるので作り直すだけでよい。`backend.tf` はそのままに `tofu apply -lock=false -target=aws_dynamodb_table.terraform_lock` を実行する（テーブルが無くても `tofu init` は通り、`-lock=false` を付ければ一時的に運用も継続できる）。

**安全策**: 大きな変更の前に `tofu state pull > ~/backup-<環境名>-$(date +%F).tfstate` でローカルバックアップを取る習慣をつけること。

## 開発環境

Nix Flake + direnv で管理。**flake（`flake.nix` / `flake.lock` / `.envrc`）はリポジトリルートにある**（この `aws/` ディレクトリではない）。ルート配下ならどこに `cd` しても direnv が同じ devShell を有効化する。

```sh
# 初回のみ（リポジトリルートで実行）
cd <repo-root> && direnv allow

# 手動で入る場合（リポジトリルートで実行）
cd <repo-root> && nix develop
```

devShell に入ってしまえば、`cd aws/environments/<env>` して `tofu` をそのまま実行できる。

## コマンド

```sh
# Format
tofu fmt -recursive -check

# Validate（各 environment ディレクトリで実行）
cd environments/management && tofu validate

# Lint
tflint --recursive

# セキュリティスキャン
trivy config .

# Plan/Apply（各 environment ディレクトリで実行）
cd environments/management && tofu plan
cd environments/management && tofu apply

# ドキュメント生成
terraform-docs markdown table environments/management
```

## ローカル環境のセットアップ(新マシン)

AWS CLI はルート flake の devShell に含まれる（`nix develop` / direnv 経由）。追加インストール不要。

SSO プロファイルは用途ごとに 5 つ構成する（いずれも IAM Identity Center の `AdministratorAccess` ロール、region `ap-northeast-1`）:

- `management-admin` — state backend（S3/DynamoDB）用
- `personal-dev-admin` / `personal-prd-admin` / `business-dev-admin` / `business-prd-admin` — 各環境 provider 用

セットアップ: `aws configure sso` を各プロファイル分実行する。SSO session を共有すれば、ブラウザでの認証は初回のみで済む。SSO start URL は IAM Identity Center の access portal URL（AWS コンソールの IAM Identity Center → Settings で確認）。

日常のログイン: `aws sso login --profile management-admin`（または共有 session 名で `aws sso login --sso-session <name>`）。

既存マシンからの移行であれば `aws configure sso` の代わりに `~/.aws/config` をコピーしてもよい。ただし `~/.aws/config` はプロファイル定義だけで、SSO のトークンキャッシュは `~/.aws/sso/cache` に別途保存されるため**コピーだけでは認証されない**。新マシンでは必ず `aws sso login --profile management-admin`（共有 session を使う場合は `aws sso login --sso-session <name>`）を実行してから `tofu init` / `tofu plan` を行うこと。

## Git Hooks (Lefthook)

- **pre-commit** (parallel): `tofu fmt -recursive -check`, `tflint --recursive`, `tofu validate`（全環境）
- **pre-push** (parallel): `secretlint`, `trivy config`

## ツール

### flake.nix で管理（flake はリポジトリルート）

- OpenTofu — IaC（Terraform 互換、コマンドは `tofu`）
- TFLint — Terraform リンター
- Trivy — セキュリティスキャナー（IaC + コンテナ + 依存関係）
- terraform-docs — ドキュメント自動生成
- AWS CLI v2
- Google Cloud SDK — `gcp/` `grafana/` スタック向け（AWS 作業では未使用）
- jq — state / JSON の検査用
- Lefthook — Git hooks
- Node.js — secretlint 実行用

### 外部サービス

- Renovate — 依存関係の自動更新（GitHub App）
