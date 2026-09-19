terraform {
  required_version = ">= 1.12.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.58.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "personal-dev-admin"
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = "dev"
    }
  }
}
