resource "google_service_account" "github-actions" {
  account_id   = "github-actions"
  project      = var.PROJECT_ID
  display_name = "A service account for GitHub Actions"
}
