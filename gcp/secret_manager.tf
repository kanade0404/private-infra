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
resource "google_secret_manager_secret_version" "otel_collector" {
  for_each    = google_secret_manager_secret.otel_collector
  secret      = each.value.id
  secret_data = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [secret_data]
  }
}
