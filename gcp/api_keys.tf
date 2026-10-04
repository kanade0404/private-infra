resource "google_apikeys_key" "aegis_youtube" {
  project      = var.PROJECT_ID
  name         = "aegis-youtube-data-api-key"
  display_name = "YouTube Data API V3 for Aegis"

  restrictions {
    api_targets {
      service = "youtube.googleapis.com"
    }
  }

  depends_on = [
    google_project_service.service["apikeys.googleapis.com"],
    google_project_service.service["youtube.googleapis.com"],
  ]
}
