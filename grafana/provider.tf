# 認証情報はハードコードせず、環境変数として供給する。
# CI では GitHub Secrets、ローカルではシェルで export してから docker compose を起動する。
#   GRAFANA_URL  … 対象 Grafana Cloud スタックの URL (例: https://xxxxx.grafana.net)
#   GRAFANA_AUTH … 上記スタックに対する Service Account トークン (Editor 以上、sensitive)
# grafana プロバイダはこれらの環境変数を自動で読み込むため、引数は不要。
provider "grafana" {}
