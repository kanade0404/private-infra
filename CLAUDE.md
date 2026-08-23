# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 言語

ユーザーへの回答は日本語で行うこと。

## Overview

個人プロジェクト `kanade0404` のクラウドインフラを 1 リポジトリで一元管理するモノレポ。
3 つの独立したスタックを持つ:

- **`gcp/`** — GCP インフラ。**Terraform** 1.11.4 + **GCS backend**（`gs://tfstate-kanade0404-terraform` / prefix `gcp`）。Docker でツールを実行。詳細は `gcp/CLAUDE.md`。
- **`aws/`** — AWS インフラ。**OpenTofu** 1.15.5 + **S3/DynamoDB** backend、AWS Organizations マルチアカウント（5 環境）。Nix flake でツールを実行。詳細は `aws/CLAUDE.md`。
- **`grafana/`** — Grafana Cloud インフラ（ダッシュボード等）。**Terraform** 1.11.4 + **GCS backend**（`gs://tfstate-kanade0404-terraform` / prefix `grafana`）。Docker でツールを実行。詳細は `grafana/CLAUDE.md`。

各スタックは backend が独立しており **state は完全に分離**している。スタックを横断する共有 state は存在しない。新しいリソースは対象クラウドのスタック配下に追加すること。

## 作業ディレクトリ

スタックごとにツールチェーンが異なるため、必ず対象ディレクトリへ移動してから作業する。

- **GCP**: `cd gcp` してから `make ...`（Docker 経由。例: `make plan` / `make apply`）
- **AWS**: `cd aws` で `nix develop`（または direnv 自動有効化）→ `cd environments/<env>` で `tofu ...`
- **Grafana**: `cd grafana` してから `make ...`（Docker 経由。例: `make plan` / `make apply`）

## CI/CD

- **GCP と Grafana** は GitHub Actions あり（`.github/workflows/`）。それぞれ `gcp/**` / `grafana/**` の変更時のみ発火し、対応するディレクトリを作業ディレクトリとして `terraform plan` / `apply` を実行する。両者は別ワークフローだが、どちらも state は同じ GCS バケット（`gs://tfstate-kanade0404-terraform`。prefix は `gcp` / `grafana` で分離）に置き、backend への認証には共通の Workload Identity Federation（`github-actions@kanade0404.iam.gserviceaccount.com`）を使う。
- **AWS は CI なし**。`plan` / `apply` は SSO ログイン済みのローカルから `tofu` で実行する。

## このリポジトリの成り立ち

`aws/` は元 `private-infra-aws` リポジトリを git subtree マージで履歴ごと取り込んだもの。統合時に backend 設定は一切変更しておらず、state は移動していない。
