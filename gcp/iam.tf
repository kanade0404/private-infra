locals {
  username = "kanade0404"
  repositories = [
    "${local.username}/private-infra",
    "${local.username}/zaim",
  ]
}
resource "google_service_account_iam_member" "admin-account-iam" {
  for_each           = toset(local.repositories)
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-actions.name}/attribute.repository/${each.value}"
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.github-actions.name
}
