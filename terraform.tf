terraform {
  required_version = "= 1.3.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.57.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "4.56.0"
    }
  }
}
