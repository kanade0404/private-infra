terraform {
  required_version = "1.6.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.1.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.1.0"
    }
  }
}
