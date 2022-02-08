resource "google_iam_workload_identity_pool" "github-oidc-pool" {
  provider                  = google-beta
  workload_identity_pool_id = "github-oidc-pool"
  project                   = var.PROJECT_ID
  depends_on = [
    google_project_service.service
  ]
}
resource "google_iam_workload_identity_pool_provider" "github-oidc-pool-provider" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.github-oidc-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc-pool-provider"
  project                            = var.PROJECT_ID
  attribute_mapping = {
    "google.subject"       = "assertion.sub",
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  depends_on = [
    google_project_service.service
  ]
}
output "workload-identity-pool-id" {
  value = google_iam_workload_identity_pool.github-oidc-pool.id
}
