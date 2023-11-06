terraform {
  required_version = "1.6.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.4.0"
    }
  }
}
