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

Nix Flake + direnv で管理。`cd` するだけで開発環境が整う。

```sh
# 初回のみ
direnv allow

# 手動で入る場合
nix develop
```

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

## Git Hooks (Lefthook)

- **pre-commit** (parallel): `tofu fmt -recursive -check`, `tflint --recursive`, `tofu validate`（全環境）
- **pre-push** (parallel): `secretlint`, `trivy config`

## ツール

### flake.nix で管理

- OpenTofu — IaC（Terraform 互換、コマンドは `tofu`）
- TFLint — Terraform リンター
- Trivy — セキュリティスキャナー（IaC + コンテナ + 依存関係）
- terraform-docs — ドキュメント自動生成
- AWS CLI v2
- Lefthook — Git hooks
- Node.js — secretlint 実行用

### 外部サービス

- Renovate — 依存関係の自動更新（GitHub App）
