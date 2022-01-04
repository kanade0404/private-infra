provider "google" {
  credentials = file("credential.json")
  project     = var.project
  region      = "asia-northeast1"
  zone        = "asia-northeast1-a"
}
