terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "kaNade"
    workspaces {
      name = "private-infra"
    }
  }
}