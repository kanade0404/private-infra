resource "google_project_service" "service" {
  for_each = toset(local.services)
  project  = var.project
  service  = each.value

}
