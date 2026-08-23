# この UID (claude-code-telemetry) のダッシュボードは Grafana MCP 経由で先行作成済み。
# overwrite = true にして、既存ダッシュボードを上書きする形で Terraform 管理下に引き継ぐ。
# (overwrite = false だと同一 uid の既存ダッシュボードに対して apply が失敗する)
resource "grafana_dashboard" "claude_code_telemetry" {
  config_json = file("${path.module}/dashboards/claude-code-telemetry.json")
  overwrite   = true
}
