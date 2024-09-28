terraform {
  required_version = "1.9.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}
resource "random_uuid" "uuid" {}
