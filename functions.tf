# resource "google_cloudfunctions_function" "scraping-zenn" {
#   name                = "scraping-zenn"
#   runtime             = "nodejs16"
#   entry_point         = "main"
#   available_memory_mb = "1024"
#   https_trigger_url   = "https://asia-northeast1-kanade0404.cloudfunctions.net/scraping-zenn"
#   labels = {
#     "deployment-tool" = "cli-gcloud"
#   }
#   min_instances = 0
#   project       = var.PROJECT_ID
#   trigger_http  = true
#   region        = "asia-northeast1"
#   timeout       = 120
#   timeouts {}
# }
