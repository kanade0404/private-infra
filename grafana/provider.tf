# 認証情報はハードコードせず、Terraform Cloud workspace の環境変数として設定する。
#   GRAFANA_URL  … 対象 Grafana Cloud スタックの URL (例: https://xxxxx.grafana.net)
#   GRAFANA_AUTH … 上記スタックに対する Service Account トークン (Editor 以上、sensitive)
# grafana プロバイダはこれらの環境変数を自動で読み込むため、引数は不要。
provider "grafana" {}
