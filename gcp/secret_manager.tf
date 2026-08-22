# OpenTelemetry Collector (Cloud Run, otel_collector.tf) が参照する Secret Manager シークレット。
# ここでは secret 本体のみを作成し、値 (version) は Terraform では管理しない。
# apply 後の手動投入手順は otel_collector.tf 冒頭のコメントを参照。
locals {
  otel_collector_secret_ids = [
    "otel-collector-findy-token",        # Findy AI+ の Bearer トークン
    "otel-collector-grafana-basic-auth", # Grafana Cloud OTLP の Basic 認証 (base64 済み "<instance_id>:<api_token>")
    "otel-collector-receiver-token",     # Collector 受信側 (otlp receiver) の Bearer トークン
  ]
}

resource "google_secret_manager_secret" "otel_collector" {
  for_each  = toset(local.otel_collector_secret_ids)
  project   = var.PROJECT_ID
  secret_id = each.value

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.service
  ]
}

# version が 1 つも無い secret を Cloud Run が env 参照すると、リビジョン作成が
# 失敗し apply がエラーになる (CI は master push で自動 apply のため必須)。
# そのためプレースホルダー値で version を 1 つ作成しておく。
# 実際の値は apply 後に `gcloud secrets versions add` で投入し、
# version = "latest" 参照により次のインスタンス起動から反映される。
#
# ただし otel-collector-receiver-token だけは「上流バックエンドへの送信」ではなく
# 「Cloud Run の公開エンドポイントへの受信」を認証するトークンであり、Cloud Run の
# IAM 自体は allUsers に roles/run.invoker を許可している (認証は Collector 内の
# bearertokenauth/receiver に委譲する設計、otel_collector.tf 参照)。そのため
# 初期 version に "PLACEHOLDER" のような既知の固定文字列を使うと、実値投入までの間
# 第三者が `Authorization: Bearer PLACEHOLDER` で任意の telemetry を送信できてしまう
# (CodeRabbit 指摘、PR #464)。random_password で推測不能な初期値を生成することで
# この期間のリスクを塞ぐ。生成された値は Terraform state に残るが、実運用では
# 上記手順で手動投入した実トークンに置き換わる前提であり、この初期値自体を
# 使い続けることは想定していない。
# findy-token / grafana-basic-auth は上流バックエンドへの認証情報であり、
# プレースホルダーのままでも各バックエンド側で 401 になるだけで受信面のリスクは
# ないため、従来どおり "PLACEHOLDER" のままとする。
resource "random_password" "otel_collector_receiver_token" {
  length  = 48
  special = false
}

resource "google_secret_manager_secret_version" "otel_collector" {
  for_each = google_secret_manager_secret.otel_collector
  secret   = each.value.id
  secret_data = (
    each.key == "otel-collector-receiver-token"
    ? random_password.otel_collector_receiver_token.result
    : "PLACEHOLDER"
  )

  lifecycle {
    ignore_changes = [secret_data]
  }
}
