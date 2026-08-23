# private-infra

GCP と AWS のインフラを一元管理するモノレポ。

- **`gcp/`** — GCP (Terraform + Terraform Cloud)。セットアップは `cd gcp && make setup`。
- **`aws/`** — AWS (OpenTofu + Nix)。セットアップはリポジトリルートで `direnv allow`（`nix develop` でも可）。

各スタックは state backend が独立しており、横断する共有 state は無い。詳細は各ディレクトリの `CLAUDE.md` を参照。

## 開発環境

リポジトリルートの Nix flake（`flake.nix` / `flake.lock` / `.envrc`）が開発ツールを提供する。ルートで一度 `direnv allow` すればサブディレクトリでも有効。
