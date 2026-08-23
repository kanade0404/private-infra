# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 言語

ユーザーへの回答は日本語で行うこと。

## Overview

個人プロジェクト `kanade0404` のクラウドインフラを 1 リポジトリで一元管理するモノレポ。
3 つの独立したスタックを持つ:

- **`gcp/`** — GCP インフラ。**Terraform** 1.11.4 + **Terraform Cloud**（org `kaNade` / workspace `private-infra`）。Docker でツールを実行。詳細は `gcp/CLAUDE.md`。
- **`aws/`** — AWS インフラ。**OpenTofu** 1.11.5 + **S3/DynamoDB** backend、AWS Organizations マルチアカウント（5 環境）。Nix flake でツールを実行。詳細は `aws/CLAUDE.md`。
- **`grafana/`** — Grafana Cloud インフラ（ダッシュボード等）。**OpenTofu** 1.11.5 + **GCS backend**（`gs://tfstate-kanade0404-terraform` / prefix `grafana`）。Nix flake でツールを実行。詳細は `grafana/CLAUDE.md`。

各スタックは backend が独立しており **state は完全に分離**している。スタックを横断する共有 state は存在しない。新しいリソースは対象クラウドのスタック配下に追加すること。

開発環境はリポジトリルートの **Nix flake**（`flake.nix` / `flake.lock` / `.envrc`）が提供する。ルートで `direnv allow`（初回のみ）すればサブディレクトリでも devShell が有効になり、`tofu` / `awscli2` / `gcloud` / `tflint` / `trivy` / `terraform-docs` / `jq` / `lefthook` / `nodejs` が揃う。現状 flake を使うのは `aws/` と `grafana/` で、`gcp/` は当面 Docker のまま（統一計画は issue #470）。

## 作業ディレクトリ

スタックごとにツールチェーンが異なるため、必ず対象ディレクトリへ移動してから作業する。

- **GCP**: `cd gcp` してから `make ...`（Docker 経由。例: `make plan` / `make apply`）
- **AWS**: リポジトリルートで `nix develop`（または direnv 自動有効化。flake はルートにある）→ `cd aws/environments/<env>` で `tofu ...`
- **Grafana**: リポジトリルートで `nix develop`（または direnv 自動有効化）→ `cd grafana` で `tofu ...`（`make plan` / `make apply` はそのラッパー）

## CI/CD

- **GCP と Grafana** は GitHub Actions あり（`.github/workflows/`）。それぞれ `gcp/**` / `grafana/**` の変更時のみ発火し、対応するディレクトリを作業ディレクトリとして plan / apply を実行する（GCP は `terraform`、Grafana は `tofu`）。両者は別ワークフローで、Grafana は GCS backend への認証に GCP と同じ Workload Identity Federation を使う（GCP は state も TFC のまま、Grafana は state を GCS に移行済み）。
- **AWS は CI なし**。`plan` / `apply` は SSO ログイン済みのローカルから `tofu` で実行する。

## このリポジトリの成り立ち

`aws/` は元 `private-infra-aws` リポジトリを git subtree マージで履歴ごと取り込んだもの。統合時に backend 設定は一切変更しておらず、state は移動していない。
