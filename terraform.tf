terraform {
  required_version = "1.6.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.11.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.10.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}
resource "random_uuid" "uuid" {}
