terraform {
  required_version = "1.12.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.35.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.35.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
resource "random_uuid" "uuid" {}
