resource "google_kms_key_ring" "infra" {
  name     = "infra"
  location = "asia-northeast1"
  depends_on = [
    google_project_service.service
  ]
}
resource "google_kms_crypto_key" "infra" {
  name            = "infra"
  key_ring        = google_kms_key_ring.infra.id
  rotation_period = "2592000s" # 30日

  lifecycle {
    prevent_destroy = true
  }
  depends_on = [
    google_project_service.service
  ]
}
