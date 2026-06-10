# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 言語

ユーザーへの回答は日本語で行うこと。

## Overview

GCP infrastructure for the personal project `kanade0404`, managed with **Terraform** (no modules — a flat set of `.tf` files under this `gcp/` directory). State lives in **Terraform Cloud** (org `kaNade`, workspace `private-infra`). Single environment, single GCP project, region `asia-northeast1`. All tooling runs inside a Docker container so versions stay pinned and consistent.

> This is the **GCP stack** of a monorepo. The sibling **AWS stack** lives at `../aws` (OpenTofu, multi-account AWS Organizations, Nix-based dev env) and has its own `CLAUDE.md` — the commands below do **not** apply there. See the repo-root `CLAUDE.md` for the umbrella overview.

## Working in the Docker container

All commands below run **from this `gcp/` directory** (`cd gcp` first). Every Terraform/gcloud command runs through `docker compose exec private_infra …`. The Makefile wraps the common ones; prefer it over raw commands.

```sh
make build        # build the Docker image
make up           # start the container (detached)
make bash         # shell into the container
make setup        # one-time: gcloud auth + project-set + terraform login + init
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

- **`lefthook.yml` is stale.** Its hooks call `docker compose exec tfgcloud …`, but the only service is `private_infra` (see `docker-compose.yaml`). The pre-commit/pre-push hooks will fail until the service name is corrected. The Makefile (`make format`, `make check`) is the working equivalent.
- Secrets/state are gitignored and secret-scanned: `credential.json`, `**/*.tfvars`, `.terraform/`. `.secretlintignore` whitelists `credential.json` and `*.tfvars` — don't commit real secrets relying on that.
- No module structure: resources are grouped by file at the root (`iam.tf`, `kms.tf`, `gcs.tf`, `gae.tf`, `service.tf`, `workload_identity.tf`, …). New resources go in the file matching their domain.
