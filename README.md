# private-infra

GCP と AWS のインフラを一元管理するモノレポ。

- **`gcp/`** — GCP (Terraform + GCS backend)。セットアップは `cd gcp && make setup`。
- **`aws/`** — AWS (OpenTofu + Nix)。セットアップは `cd aws && direnv allow`。

各スタックは state backend が独立しており、横断する共有 state は無い。詳細は各ディレクトリの `CLAUDE.md` を参照。
