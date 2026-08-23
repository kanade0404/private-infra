provider "google" {
  project = var.PROJECT_ID
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}
provider "google-beta" {
  project = var.PROJECT_ID
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}
provider "random" {}
