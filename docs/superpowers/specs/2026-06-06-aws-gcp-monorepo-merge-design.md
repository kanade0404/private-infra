# private-infra-aws を private-infra にモノレポ統合する設計

- 日付: 2026-06-06
- 対象リポジトリ: `private-infra`（統合先 / git ルート）, `private-infra-aws`（取込元）
- ステータス: 設計承認済み（実装計画フェーズへ）

## 1. 背景と目的

GCP インフラ（`private-infra`）と AWS インフラ（`private-infra-aws`）を、リポジトリを分けずに 1 つのリポジトリで一元管理したい。実際のクラウドリソースに影響を与えずに統合することが必須要件。

### 現状（統合前）

| | private-infra (GCP) | private-infra-aws (AWS) |
|---|---|---|
| IaC ツール | Terraform 1.11.4 | OpenTofu 1.15.5 |
| state backend | Terraform Cloud (`remote`, org `kaNade` / workspace `private-infra`) | S3 + DynamoDB（management アカウント, bucket `private-infra-aws-tfstate`, table `terraform-lock`） |
| config 構造 | ルート直下にフラットな `*.tf`（モジュールなし） | `environments/` 配下に 5 つの独立 root module |
| dev 環境 | Docker（docker-compose + Makefile） | Nix flake + direnv |
| CI | GitHub Actions（plan/apply/actionlint） | なし |
| リージョン | asia-northeast1 | ap-northeast-1 |

## 2. 方針（決定事項）

1. **統合レベル: モノレポ化のみ（最小リスク）**。IaC ツール（Terraform / OpenTofu）も state backend（TFC / S3）も現状維持。バックエンドの統合・ツール標準化は行わない。
2. **ディレクトリ構成: 対称配置** `gcp/` と `aws/`。
3. **git 履歴: 保存**（subtree マージで `private-infra-aws` のコミット履歴を `aws/` 配下に保持）。
4. **CI: GCP ワークフローに path filter 追加のみ**。AWS の CI 新設・OIDC 整備は本スコープ外。

### 重要な前提（リスク低減の根拠）

各 config の backend 設定（TFC workspace 名、S3 の bucket/key）は**ファイルの配置場所に依存しない**。ファイルをサブディレクトリへ移動しても backend 設定は不変なので、`init` は既存の state を再認識し、**state は物理的に移動しない**。したがってリソースへの影響はゼロ。本作業の「state 移行」は、実体としては「コード再配置 + state はその場に維持 + 差分ゼロ検証」である。

## 3. 最終ディレクトリ構成

```
private-infra/                  (git ルート＝統合先)
├── gcp/                        ← 現ルートの GCP 一式を移動
│   ├── *.tf                    (backend.tf 等そのまま, workspace=private-infra 不変)
│   ├── .terraform-version
│   ├── Makefile
│   ├── docker-compose.yaml
│   ├── docker/local/Dockerfile
│   └── CLAUDE.md               (現ルート CLAUDE.md を移設・パス修正)
├── aws/                        ← subtree マージで履歴ごと取込
│   ├── environments/
│   │   ├── management/
│   │   ├── personal-dev/
│   │   ├── personal-prd/
│   │   ├── business-dev/
│   │   └── business-prd/
│   ├── flake.nix
│   ├── flake.lock
│   ├── lefthook.yml
│   ├── .secretlintrc.json
│   └── CLAUDE.md               (既存 AWS CLAUDE.md をそのまま維持)
├── .github/workflows/          (GCP ワークフロー + path filter)
├── CLAUDE.md                   (新規: 統合ルート用アンブレラ)
├── README.md
├── renovate.json
└── .gitignore                  (両者マージ)
```

## 4. 取り込み手順（git 履歴保存）

統合先 `private-infra` 上で実行する。

1. `git remote add aws <private-infra-aws のパス>` → `git fetch aws`
2. `git merge -s ours --allow-unrelated-histories --no-commit aws/master`
3. `git read-tree --prefix=aws/ -u aws/master` → `git commit`（AWS の履歴が `aws/` 配下に保存される）
4. 別コミットで現ルートの GCP ファイル一式を `git mv` で `gcp/` へ移動（`*.tf`, `.terraform-version`, `Makefile`, `docker-compose.yaml`, `docker/`）
5. ルート `CLAUDE.md` を `gcp/CLAUDE.md` へ移設し、新ルート `CLAUDE.md`（アンブレラ）を作成

> 注: 取込元のブランチ名が `master` でない場合は実際のデフォルトブランチ名に読み替える。

## 5. state 安全移行手順（リソース影響ゼロの肝）

対象は GCP×1 + AWS 環境×5 = 計 6 config。各 config で**移動前後に差分ゼロを検証**する。

- **移動前（ベースライン採取）**: `state list` と `plan` を採取。既存環境なので no change のはず。
- **移動後（検証）**: `init`（同じ backend を再認識）→ `plan`。
- **判定基準**: `add` / `change` / `destroy` / `replace` が **1 件でも出たら中断**して原因調査。backend 不変のため本来は空 plan になる。

| config | ツール | 検証コマンド（移動後ディレクトリで） |
|---|---|---|
| GCP | terraform | `terraform init` → `terraform plan` |
| AWS management | tofu | `tofu init` → `tofu plan` |
| AWS personal-dev | tofu | `tofu init` → `tofu plan` |
| AWS personal-prd | tofu | `tofu init` → `tofu plan` |
| AWS business-dev | tofu | `tofu init` → `tofu plan` |
| AWS business-prd | tofu | `tofu init` → `tofu plan` |

### 実行前チェック

- GCP の TFC workspace `private-infra` が **VCS 連携で working-directory に依存していないか**確認する。CI は GHA 上で WIF 認証して `terraform` を実行しており、ローカル実行モードと推定されるが、もし VCS 連携 + working-directory 設定がある場合は、ルートから `gcp/` へ移動するのに合わせて TFC 側の Terraform Working Directory 設定を更新する必要がある。
- AWS は S3 backend の `key` がアカウント別に固定（例: `business-prd/terraform.tfstate`）で配置非依存。追加対応不要。

## 6. CI/CD（GCP に path filter のみ）

`plan_terraform.yaml` / `apply_terraform.yaml` に対し:

- トリガに path filter を追加: `on.<event>.paths: ['gcp/**', '.github/workflows/**']`
- ジョブの `run` ステップを `gcp` ディレクトリで実行するよう `defaults.run.working-directory: gcp` を設定（`fmt` / `init` / `validate` / `tfsec .` / `tfcmt plan` が対象）
- `reviewdog/action-tflint` はアクションのため、その `working_directory` 入力を `gcp` に設定
- `actions.yaml`（actionlint）は変更不要

AWS 側の CI は新設しない（現状維持）。将来 AWS CI を追加する場合は AWS の OIDC/WIF 認証基盤の整備が前提となる（別スコープ）。

## 7. dev 環境・ドキュメント

- 2 つのツールチェーンを併存維持:
  - GCP: `cd gcp && make ...`（Docker）
  - AWS: `cd aws && nix develop`（または direnv 自動有効化）
- 新ルート `CLAUDE.md` は「2 スタック構成」の入口として、`gcp/CLAUDE.md`・`aws/CLAUDE.md` へ誘導するアンブレラとする。
- `gcp/CLAUDE.md` は現ルート CLAUDE.md の内容を移設し、コマンドのパス（`cd gcp` 前提）を修正。
- `.gitignore` は両リポジトリの内容をマージしてルートに集約（両者とも `.terraform/`, `*.tfvars` 等を ignore）。

## 8. 実行方法

承認済み設計 → 本 spec → writing-plans で実装計画作成 → **workflow で実行**。
workflow では各 stack（GCP + AWS 5 環境）の「ベースライン採取 → ファイル移動 → init → plan 差分検証」をエージェントで分担し、差分ゼロを検証する。差分が出た stack は中断・報告する。

## 9. スコープ外（YAGNI）

- state backend の統合（TFC ↔ S3 の一本化）
- IaC ツールの標準化（Terraform / OpenTofu のどちらかへ統一）
- AWS 側 CI/CD の新設および AWS OIDC 認証基盤の構築
- 既存リソース定義のリファクタリング

## 10. リスクと緩和

| リスク | 緩和策 |
|---|---|
| ファイル移動で state が孤立しリソース再作成される | backend 設定を一切変更しない。移動後 `plan` 差分ゼロを必須ゲートにする |
| TFC workspace の working-directory 依存 | 実行前チェックで確認、必要なら TFC 設定を更新 |
| マージ後に AWS 変更で GCP CI が誤発火 | GCP ワークフローに `gcp/**` path filter を追加 |
| GCP の Makefile/Docker がパス前提でファイル移動後に壊れる | Makefile・docker-compose を `gcp/` へ同梱し `cd gcp` 前提に統一 |
| subtree マージ時のブランチ名差異 | 取込元のデフォルトブランチ名を事前確認 |
