terraform {
  required_version = "1.15.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
  }
}
resource "random_uuid" "uuid" {}
