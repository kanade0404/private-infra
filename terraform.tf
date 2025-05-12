terraform {
  required_version = "1.11.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.34.1"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.34.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}
resource "random_uuid" "uuid" {}
