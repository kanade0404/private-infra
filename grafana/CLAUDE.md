# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 言語

ユーザーへの回答は日本語で行うこと。

## Overview

Grafana Cloud (kanade0404 個人スタック) のダッシュボード / リソースを管理する **OpenTofu** スタック（1.11.5）。state は **GCS バケット** `gs://tfstate-kanade0404-terraform`（prefix `grafana`）に置く。プロバイダは `grafana/grafana`（provider registry は `registry.opentofu.org`）。

> これはモノレポの **Grafana スタック** です。兄弟スタックの **GCP** (`../gcp`) と **AWS** (`../aws`) はそれぞれ独立した backend を持ち、state は完全に分離しています。詳細はリポジトリルートの `CLAUDE.md` を参照。

## 認証の仕組み

### Grafana provider

- `provider.tf` の `provider "grafana" {}` は引数を取らない。認証は環境変数 `GRAFANA_URL` / `GRAFANA_AUTH` から自動で読み込まれる（`grafana/grafana` provider の標準挙動）。
- CI ではこれらの値を **GitHub Secrets**（`GRAFANA_URL` / `GRAFANA_AUTH`）から供給する。ローカル実行時は、シェルで `export GRAFANA_URL=... GRAFANA_AUTH=...` してから `tofu` を実行すること。
- `GRAFANA_AUTH` に使う Service Account トークンには、管理対象リソース（ダッシュボード等）に対して最低でも **Editor** 権限が必要。
- リポジトリ内にトークン等の秘密情報は一切置かない。

### GCS backend (state)

- state は GCS バケット `gs://tfstate-kanade0404-terraform`（prefix `grafana`）に保存する。
- CI (`github-actions@kanade0404.iam.gserviceaccount.com`) は Workload Identity Federation で認証し、当該バケットへの `roles/storage.objectAdmin` を保持している。
- ローカルから `tofu plan` / `apply` する場合は、事前にホストで `gcloud auth application-default login` を実行しておくこと。実行すると `~/.config/gcloud/application_default_credentials.json` に Application Default Credentials (ADC) が生成され、`tofu` は追加設定なしでこの ADC を GCS backend の認証に使う。Docker コンテナを介さなくなったため、ADC ファイルのマウントや `GOOGLE_APPLICATION_CREDENTIALS` の指定は不要。
- `make login`（旧 `terraform login`）は不要になったため廃止した。

## ツールチェーン (Nix)

ツールはリポジトリルートの **Nix flake**（`flake.nix` / `flake.lock` / `.envrc`）が提供する。OpenTofu 1.11.5 / gcloud SDK / jq などが devShell に入っている。Docker / docker-compose は使わない。

```sh
# 初回のみ（リポジトリルートで）
direnv allow          # direnv を使わない場合は `nix develop` でも可
```

以降 `cd grafana` して `tofu` を直接叩ける。都度シェルに入りたくない場合は `nix develop -c tofu <…>` でも良い。

ローカルで `plan` / `apply` する前に、ホスト側で以下を済ませておくこと:

```sh
gcloud auth application-default login          # GCS backend への認証 (ADC)
export GRAFANA_URL=https://xxxxx.grafana.net   # 対象 Grafana Cloud スタックの URL
export GRAFANA_AUTH=...                        # Service Account トークン (Editor 以上)
```

## Common commands

All commands below run **from this `grafana/` directory** (`cd grafana` first)。`Makefile` は `tofu` の薄いラッパー。

```sh
make format       # tofu fmt -recursive  +  tofu validate
make plan         # tofu plan
make apply        # tofu apply   (CI が master push で実行するのが基本)
make init         # tofu init
```

`tofu <…>` を直接実行しても同じ。

## CI/CD (GitHub Actions)

- PR で `grafana/**` に変更があると plan ワークフローが走り、plan して結果を PR にコメントする。
- `master` への push で apply ワークフローが走る。
- GCP 用ワークフローとは別ファイルだが、GCS backend への認証は GCP と同じ Workload Identity Federation（`github-actions@kanade0404.iam.gserviceaccount.com`）を使う。Grafana provider 用に `GRAFANA_URL` / `GRAFANA_AUTH` の GitHub Secrets を別途参照する。GCP 用ワークフロー自体は変更しない。

## ダッシュボード更新フロー

- ダッシュボードの実体は `dashboards/*.json`（Grafana のダッシュボード JSON モデル）。UI で編集するのではなく、この JSON を直接編集して PR を出す。
- `dashboard.tf` の `grafana_dashboard` リソースが `config_json = file(...)` でこの JSON を読み込み、`overwrite = true` で反映する。
  - `overwrite = true` にしているのは、`claude-code-telemetry` ダッシュボードが Grafana MCP 経由で先行作成済みのものを OpenTofu 管理に引き継いだため。同一 `uid` の既存ダッシュボードを上書きする形になる。
- 新しいダッシュボードを追加する場合は `dashboards/` に JSON を追加し、対応する `grafana_dashboard` リソースを `dashboard.tf`（または新規ファイル）に定義する。JSON の **top-level `id` フィールドは含めないこと**（Grafana 側で採番される内部 ID であり、OpenTofu 管理と衝突する）。`uid` は安定した文字列で明示的に指定する。
- JSON の構文チェックは `jq . dashboards/*.json`（または `python3 -m json.tool`）で行える。

## Gotchas

- モジュール構造は取らず、`gcp/` と同じくフラットな `.tf` ファイル構成。
- `grafana/` 配下は Grafana Cloud のみを対象とし、GCP/AWS のリソースとは無関係。誤って `gcp/` や `aws/` のリソースをここに追加しないこと。
