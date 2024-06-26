terraform {
  required_version = "1.7.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.24.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.24.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}
resource "random_uuid" "uuid" {}
