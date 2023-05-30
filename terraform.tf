terraform {
  required_version = "1.4.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.67.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "4.66.0"
    }
  }
}
