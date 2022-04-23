variable "repo-name" {
  type    = string
  default = "Seiya-Min/private-infra"
}
resource "google_service_account_iam_member" "admin-account-iam" {
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${var.repo-name}"
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.github-actions.name
}