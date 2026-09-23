# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 言語

ユーザーへの回答は日本語で行うこと。

## Overview

GCP infrastructure for the personal project `kanade0404`, managed with **Terraform** (no modules — a flat set of `.tf` files under this `gcp/` directory). State lives in a **GCS バケット** `gs://tfstate-kanade0404-terraform`（prefix `gcp`）。かつては Terraform Cloud（org `kaNade` / workspace `private-infra`）に置いていたが、GCS backend へ移行済み。Single environment, single GCP project, region `asia-northeast1`. All tooling runs inside a Docker container so versions stay pinned and consistent.

> This is the **GCP stack** of a monorepo. The sibling **AWS stack** lives at `../aws` (OpenTofu, multi-account AWS Organizations, Nix-based dev env) and has its own `CLAUDE.md` — the commands below do **not** apply there. See the repo-root `CLAUDE.md` for the umbrella overview.

## 認証の仕組み

backend（state）も google / google-beta provider も、認証は **ADC (Application Default Credentials) に一本化**している。`provider.tf` に `credentials` 引数は無く、サービスアカウントキーの JSON をリポジトリや環境変数に置くこともしない。

### ローカル

- 事前にホスト側で `gcloud auth application-default login` を実行しておくこと。`~/.config/gcloud/application_default_credentials.json` に ADC が生成される。
- `docker-compose.yaml` はこの ADC ファイル 1 つだけをコンテナの `/tmp/application_default_credentials.json` へ read-only でマウントし（`~/.config/gcloud` ディレクトリ全体はマウントしない。他の認証情報の露出を避けるため）、`GOOGLE_APPLICATION_CREDENTIALS` でそのパスを指す。コンテナ内の `terraform` は GCS backend / provider の両方でこの ADC を利用する。
- `make setup` の `gcloud auth …` はコンテナ内の gcloud CLI 操作用であり、Terraform の認証はホスト側の ADC マウントで賄われる点に注意。
- `make login`（旧 `terraform login`）は Terraform Cloud 用だったため廃止した。

### CI

- **Workload Identity Federation** で `github-actions@kanade0404.iam.gserviceaccount.com` を借用する（静的キーなし）。`google-github-actions/auth` が発行する認証情報が ADC として backend と provider の両方に効く。
- 当該サービスアカウントは state バケットへの `roles/storage.objectAdmin` を保持している。

## Working in the Docker container

All commands below run **from this `gcp/` directory** (`cd gcp` first). Every Terraform/gcloud command runs through `docker compose exec private_infra …`. The Makefile wraps the common ones; prefer it over raw commands.

```sh
make build        # build the Docker image
make up           # start the container (detached)
make bash         # shell into the container
make setup        # one-time: gcloud auth + project-set + init
```

## Common commands

```sh
make format       # terraform fmt -recursive  +  terraform validate
make check        # tflint  +  tfsec .
make plan         # terraform plan
make apply        # terraform apply   (CI normally does this on master)
make init         # terraform init
make upgrade      # terraform init -upgrade  (bump provider versions in lock)
```

Run a one-off command directly: `docker compose exec private_infra terraform <…>`.

## CI/CD (GitHub Actions)

- **`plan_terraform.yaml`** — on PRs: fmt-check → init → validate → tflint → tfsec → `tfcmt plan` (posts plan as a PR comment) → Slack.
- **`apply_terraform.yaml`** — on push to `master`: same checks → `tfcmt apply … -auto-approve`.
- **`actions.yaml`** — lints workflow files with `actionlint`.

GCP auth in CI uses **Workload Identity Federation** (no static keys): pool `gh-oidc-pool`, provider `github-actions`, service account `github-actions@kanade0404.iam.gserviceaccount.com`. These are themselves defined in `workload_identity.tf` / `service_account.tf` / `iam.tf` — changing them can lock CI out of the project, so plan carefully.

## Pinned tool versions (do not change ad hoc)

- Terraform `1.11.4` (`.terraform-version`, and the `hashicorp/terraform` stage in `docker/local/Dockerfile`)
- Providers `google` / `google-beta` `6.35.0`, `random` `3.7.2`
- `tfsec` `1.15.4`, plus `tflint`, `secretlint`, `actionlint`

Provider/version bumps are driven by **Renovate** (config extends `kanade0404/renovate-config`); prefer letting Renovate PRs update them.

## Gotchas

- **Lefthook の設定はリポジトリルートの `lefthook.yml` に集約済み。** かつてここにあった `gcp/lefthook.yml` は、(a) lefthook 2.x がリポジトリルートの設定しか読まないためそもそも読み込まれておらず、(b) 存在しないサービス名 `tfgcloud` を指していた（実在するのは `private_infra`）という二重の理由で機能していなかった。現在はルートの設定で service 名を `private_infra` に修正したうえで、`docker ps` で **コンテナが起動しているときだけ** fmt/tflint/validate/tfsec を実行し、未起動なら skip する。したがってコンテナを上げていないときは従来どおり Makefile（`make format`, `make check`）と GitHub Actions が正。旧設定にあった `actionlint` は引き継いでいない（`actions.yaml` ワークフローが担当）。
- Secrets/state are gitignored and secret-scanned: `credential.json`, `**/*.tfvars`, `.terraform/`. `.secretlintignore` whitelists `credential.json` and `*.tfvars` — don't commit real secrets relying on that.
- No module structure: resources are grouped by file at the root (`iam.tf`, `kms.tf`, `gcs.tf`, `gae.tf`, `service.tf`, `workload_identity.tf`, …). New resources go in the file matching their domain.
