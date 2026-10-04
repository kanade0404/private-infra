# CLAUDE.md

## 言語

ユーザーへの回答は日本語で行うこと。

## Overview

GCP project `kanade0404` の Terraform スタック。region は `asia-northeast1`。モジュールは使わず、`.tf` ファイルを用途別に配置する。state は GCS `gs://tfstate-kanade0404-terraform` の prefix `gcp`。AWS・Grafana とは独立している。

## 開発環境と認証

ルートで `nix develop`（または `direnv allow`）を実行する。Terraform 1.16.5 / gcloud / TFLint / Trivy は Nix devShell が提供する。

backend と google / google-beta provider は ADC (Application Default Credentials) で認証する。`provider.tf` に credentials 引数は無く、鍵 JSON は不要。ホストで `gcloud auth login` と `gcloud auth application-default login` を実行する。gcloud CLI と ADC は別認証なので、必要に応じて両方更新する。初回セットアップはルートの `scripts/setup gcp` で実行する。

CI は Workload Identity Federation で `github-actions@kanade0404.iam.gserviceaccount.com` を借用し、backend と provider の両方へ認証する。state バケットへの権限は `roles/storage.objectAdmin`。認証基盤は `workload_identity.tf` / `service_account.tf` / `iam.tf` が管理している。

## コマンド

devShell に入り、`cd gcp` してから直接実行する。

```sh
terraform init
terraform fmt -check
terraform validate
tflint
trivy config --exit-code 1 .
terraform plan
terraform apply
```

プロバイダの更新時のみ `terraform init -upgrade` を使う。ルートから単発実行するなら `nix develop --command terraform -chdir=gcp <command>`。

## CI/CD

- `plan_terraform.yaml`: PR で fmt / init / validate / TFLint / Trivy → tfcmt plan → Slack。
- `apply_terraform.yaml`: master push で同じチェック → tfcmt apply。
- Trivy は `nix run ..#trivy -- config --exit-code 1 .` で、ローカルと同じ flake.lock の版を使う。CI の指摘は従来同様 advisory（continue-on-error）。
- `actions.yaml`: actionlint。

## バージョン管理

Terraform 1.16.5 は `terraform.tf` と `flake.nix`（公式バイナリと全対応 platform の SHA-256）、CI に固定する。更新時はこれらを揃える。その他の CLI は flake.lock に固定する。プロバイダの版は `terraform.tf` と `.terraform.lock.hcl` を参照し、Renovate の更新方針を維持する。

## Git hooks と注意点

ルートの `lefthook.yml` を使い、変更対象のスタックだけを検査する。GCP も Nix devShell の CLI で fmt / lint / validate / Trivy を実行する。Git hooks は通常のシェルからも Nix 経由で起動する。Trivy の検出結果は CI と同様に advisory とし、スキャナー自体のエラーは失敗させる。validate は init が済んでいない場合に理由を表示してスキップする。認証不要の検証には一時コピーで `terraform init -backend=false` を使える。

秘密情報はコミットしない。`credential.json` / `*.tfvars` / `.terraform/` は gitignored。`.secretlintignore` の除外を秘密情報の保護手段として扱わない。
