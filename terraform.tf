terraform {
  required_version = "1.11.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.27.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
  }
}
resource "random_uuid" "uuid" {}
