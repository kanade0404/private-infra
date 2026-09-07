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

各ディレクトリは独立した Terraform root module。State は管理アカウントの S3 バケットに保存。

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
