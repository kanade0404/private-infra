resource "google_project_iam_member" "scraping-zenn-impersonate" {
  project = var.PROJECT_ID
  role    = "roles/iam.workloadIdentityUser"
  member  = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-oidc-pool.id}/attribute.repository/Seiya-Min/scraping-zenn"
  depends_on = [
    google_iam_workload_identity_pool.github-oidc-pool
  ]
}
