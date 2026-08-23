# OpenTelemetry Collector を Cloud Run にデプロイし、Claude Code の OTLP テレメトリを
# Findy AI+ と Grafana Cloud の両方へファンアウトする。
#
# Findy AI+ 向け exporter は encoding: json / compression: none が必須
# (gzip / protobuf を送ると Findy 側の API Gateway が 400 を返す)。
#
# 非同期の sending_queue をきちんと flush させるため、instance-based billing
# (CPU always allocated, resources.cpu_idle = false) を使う。
#
# --- apply 後の手動手順 ------------------------------------------------
#
# 1. Secret Manager の 3 つの secret に値を投入する (Terraform ではプレースホルダー
#    version のみ管理する。apply 後いつでも可: プレースホルダーのままでも apply は
#    成功し、実値投入まで Collector は各バックエンドへの送信が 401 になるだけ)。
#    gcloud は Docker コンテナ経由で実行する (gcp/CLAUDE.md 参照。gcp/ で実行):
#
#      echo -n "<Findy AI+ の Bearer トークン>" | \
#        docker compose exec -T private_infra gcloud secrets versions add \
#        otel-collector-findy-token --project="$PROJECT_ID" --data-file=-
#
#      echo -n "<Grafana Cloud の instance_id:api_token を base64 したもの>" | \
#        docker compose exec -T private_infra gcloud secrets versions add \
#        otel-collector-grafana-basic-auth --project="$PROJECT_ID" --data-file=-
#
#      echo -n "<Collector 受信側 (otlp receiver) の Bearer トークン>" | \
#        docker compose exec -T private_infra gcloud secrets versions add \
#        otel-collector-receiver-token --project="$PROJECT_ID" --data-file=-
#
#    Grafana Cloud の Basic 認証値は以下で作成できる:
#
#      echo -n "<instance_id>:<api_token>" | base64
#
#    Cloud Run の env var 経由の secret は「インスタンス起動時」に解決され、
#    起動済みインスタンスは値投入後も再取得しない (Google 公式ドキュメント通り。
#    https://cloud.google.com/run/docs/configuring/services/secrets)。
#
#    - min_instance_count = 0 のため通常はインスタンスが存在せず、次のリクエストで
#      起動する新インスタンスが secret の最新 version を解決する。多くの場合、
#      追加の操作は不要。
#    - 稼働中のインスタンスに確実に反映させたい場合 (token ローテーション時など)は、
#      現在と同一のイメージを指定して gcloud run deploy を実行し、新しいリビジョンを
#      強制作成する (config が同一でも gcloud run deploy は必ず新リビジョンを作るため、
#      Terraform 管理下の設定に差分は生じない。gcloud run services update は設定変更
#      フラグなしでは "nothing to update" エラーになり新リビジョンを作らないので使わない):
#
#      docker compose exec -T private_infra gcloud run deploy otel-collector \
#        --image="asia-northeast1-docker.pkg.dev/$PROJECT_ID/docker-hub-remote/otel/opentelemetry-collector-contrib:0.159.0" \
#        --region=asia-northeast1 --project="$PROJECT_ID"
#
#      反映確認 (latestReadyRevisionName が更新されていることを確認する):
#
#      docker compose exec -T private_infra gcloud run services describe otel-collector \
#        --region=asia-northeast1 --project="$PROJECT_ID" \
#        --format='value(status.latestReadyRevisionName)'
#
# 2. Claude Code 側 (dotfiles の settings.json) の OTLP エンドポイントを、
#    この Cloud Run サービスの URL (output "otel_collector_url" 参照) に向ける。
#    受信には RECEIVER_TOKEN の Bearer トークンが必要 (dotfiles 側の変更はスコープ外)。
#
# --- 運用上の注意 --------------------------------------------------------
#
# - min_instance_count = 0 のため、アイドルでのインスタンス破棄時に in-memory
#   sending_queue の未送信分が失われ得る (個人テレメトリのため許容。
#   許容できなくなったら min 1 に)。
# - 初回 apply は artifactregistry API 有効化の伝播遅延で失敗することがある
#   (再実行で解消)。
# - CI の SA での apply には、新規 SA への iam.serviceAccounts.actAs、
#   run.services.setIamPolicy、artifactregistry.repositories.create、
#   secretmanager.secrets.setIamPolicy 権限が必要 (CI SA が Editor/Owner
#   相当なら不要)。
# - Findy のエンドポイント URL (ステージパス無し) は 2026-08-22 に
#   /v1/metrics /v1/logs への直接 POST で 200 を実測確認済み。
# - metrics は temporality の要求差により Findy 向け / Grafana 向けでパイプラインを
#   分けている (delta_to_cumulative processor のコメント参照)。
# - grafana_otlp_endpoint 変数の default はサンプル値であり、自分の
#   Grafana Cloud スタックの OTLP gateway URL に合わせて上書きが必要
#   (未設定でも Grafana 側が 401 になるだけで Findy 転送には影響しない)。
# ------------------------------------------------------------------------

resource "google_service_account" "otel_collector" {
  account_id   = "otel-collector"
  project      = var.PROJECT_ID
  display_name = "Service account for the OpenTelemetry Collector Cloud Run service"
}

resource "google_secret_manager_secret_iam_member" "otel_collector" {
  for_each  = google_secret_manager_secret.otel_collector
  project   = var.PROJECT_ID
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.otel_collector.email}"
}

locals {
  # Terraform の interpolation と衝突するため、Collector 側の環境変数展開
  # (${env:...}) はすべて $${env:...} にエスケープしている。
  otel_collector_config = <<-YAML
    extensions:
      health_check:
        endpoint: 0.0.0.0:13133
      bearertokenauth/receiver:
        token: $${env:RECEIVER_TOKEN}

    receivers:
      otlp:
        protocols:
          http:
            endpoint: 0.0.0.0:4318
            auth:
              authenticator: bearertokenauth/receiver

    exporters:
      otlp_http/findy:
        endpoint: https://dapbih69d4.execute-api.ap-northeast-1.amazonaws.com
        encoding: json
        compression: none
        headers:
          Authorization: "Bearer $${env:FINDY_TOKEN}"
        retry_on_failure:
          enabled: true
        sending_queue:
          enabled: true
      otlp_http/grafana:
        endpoint: $${env:GRAFANA_OTLP_ENDPOINT}
        headers:
          Authorization: "Basic $${env:GRAFANA_BASIC_AUTH}"
        retry_on_failure:
          enabled: true
        sending_queue:
          enabled: true
          # default の 10 consumer が並行送信すると同一時系列のサンプルが順序逆転
          # して届き得る。cumulative (delta_to_cumulative 変換後) は順序に意味があり、
          # Mimir は out-of-order window を超えた古いサンプルを拒否するため 1 に絞る。
          # 個人利用のスループットなら 1 consumer で十分。
          num_consumers: 1

    processors:
      # Grafana Cloud (Mimir) は cumulative temporality しか受け付けず、Claude Code の
      # OTel SDK が送る delta の Sum は HTTP 400 (invalid temporality and type
      # combination) で全ドロップされるため、Grafana 向けだけ cumulative に変換する。
      # (正式な type 名は delta_to_cumulative。deltatocumulative は非推奨エイリアス)
      delta_to_cumulative:
        # 同時に state を保持する時系列数の上限。個人テレメトリの規模には十分で、
        # かつメモリ (limits.memory = 512Mi) の暴走を防ぐ値。
        max_streams: 10000
        # 更新が途絶えた時系列の state を破棄するまでの猶予。Claude Code のセッションは
        # 断続的なので default の 5m より長めに取る。ただし min_instance_count = 0 の
        # ためアイドルでインスタンスごと state が消える (プロセス生存期間が実質の上限)
        # ので、これ以上長い値を設定しても意味は無い。
        max_stale: 30m

    service:
      extensions: [health_check, bearertokenauth/receiver]
      pipelines:
        # metrics はバックエンドが要求する temporality が異なるためパイプラインを分ける。
        # Findy AI+ は delta のまま 200 で受理しているので変換せずに送る。
        metrics:
          receivers: [otlp]
          exporters: [otlp_http/findy]
        # Grafana Cloud 向けのみ delta -> cumulative へ変換して送る。
        metrics/grafana:
          receivers: [otlp]
          processors: [delta_to_cumulative]
          exporters: [otlp_http/grafana]
        logs:
          receivers: [otlp]
          exporters: [otlp_http/findy, otlp_http/grafana]
  YAML
}

resource "google_cloud_run_v2_service" "otel_collector" {
  name                = "otel-collector"
  project             = var.PROJECT_ID
  location            = local.location
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account = google_service_account.otel_collector.email

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = "${local.location}-docker.pkg.dev/${var.PROJECT_ID}/${google_artifact_registry_repository.docker_hub.repository_id}/otel/opentelemetry-collector-contrib:0.159.0"
      args  = ["--config=env:OTEL_CONFIG"]

      ports {
        container_port = 4318
      }

      resources {
        # instance-based billing: CPU を常時割り当てて、非同期 sending_queue の
        # flush がリクエスト外でも実行されるようにする。
        cpu_idle          = false
        startup_cpu_boost = true
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      startup_probe {
        http_get {
          path = "/"
          port = 13133
        }
      }

      env {
        name  = "OTEL_CONFIG"
        value = local.otel_collector_config
      }

      env {
        name  = "GRAFANA_OTLP_ENDPOINT"
        value = var.grafana_otlp_endpoint
      }

      env {
        name = "FINDY_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.otel_collector["otel-collector-findy-token"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "GRAFANA_BASIC_AUTH"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.otel_collector["otel-collector-grafana-basic-auth"].secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "RECEIVER_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.otel_collector["otel-collector-receiver-token"].secret_id
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [
    google_project_service.service,
    google_artifact_registry_repository.docker_hub,
    google_secret_manager_secret_iam_member.otel_collector,
    google_secret_manager_secret_version.otel_collector,
  ]
}

# 認証は Collector 内の bearertokenauth/receiver (RECEIVER_TOKEN) で行うため、
# Cloud Run の IAM 自体は allUsers に invoker を許可する。
resource "google_cloud_run_v2_service_iam_member" "otel_collector_invoker" {
  project  = var.PROJECT_ID
  location = google_cloud_run_v2_service.otel_collector.location
  name     = google_cloud_run_v2_service.otel_collector.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "otel_collector_url" {
  description = "OpenTelemetry Collector (Cloud Run) の URL"
  value       = google_cloud_run_v2_service.otel_collector.uri
}
