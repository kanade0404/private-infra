resource "google_app_engine_application" "firestore" {
  project       = var.PROJECT_ID
  location_id   = "asia-northeast1"
  database_type = "CLOUD_FIRESTORE"
  depends_on = [
    google_project_service.service
  ]
}
