resource "google_iam_workload_identity_pool" "github-actions" {
  provider                  = google-beta
  workload_identity_pool_id = "gh-oidc-pool"
  project                   = var.PROJECT_ID
  display_name              = "gh-oidc-pool"
  description               = "Workload Identity Pool for GitHub Actions"
  depends_on = [
    google_project_service.service
  ]
}

resource "google_iam_workload_identity_pool_provider" "github-actions" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.github-actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "github-actions"
  description                        = "OIDC identity pool provider for GiHub Actions"
  project                            = var.PROJECT_ID
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}