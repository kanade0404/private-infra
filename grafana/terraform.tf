terraform {
  required_version = "1.11.4"
  cloud {
    organization = "kaNade"
    workspaces {
      name = "private-infra-grafana"
    }
  }
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}
