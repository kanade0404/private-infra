provider "google" {
  credentials = var.GOOGLE_CREDENTIALS
  project     = var.PROJECT_ID
  region      = "asia-northeast1"
  zone        = "asia-northeast1-a"
}
provider "google-beta" {
  project     = var.PROJECT_ID
  credentials = var.GOOGLE_CREDENTIALS
  region      = "asia-northeast1"
  zone        = "asia-northeast1-a"
}
