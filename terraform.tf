terraform {
  required_version = "1.4.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.56.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "4.56.0"
    }
  }
}
