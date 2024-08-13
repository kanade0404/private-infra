terraform {
  required_version = "1.9.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.41.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.41.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
resource "random_uuid" "uuid" {}
