terraform {
  required_version = "1.11.4"
  backend "gcs" {
    bucket = "tfstate-kanade0404-terraform"
    prefix = "grafana"
  }
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}
