terraform {
  required_version = "1.6.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.7.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.7.0"
    }
  }
}
