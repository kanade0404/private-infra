terraform {
  backend "gcs" {
    bucket = "tfstate-kanade0404-terraform"
    prefix = "gcp"
  }
}
