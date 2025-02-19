terraform {
  required_version = "1.10.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.21.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.20.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}
resource "random_uuid" "uuid" {}
