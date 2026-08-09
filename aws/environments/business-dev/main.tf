terraform {
  required_version = "1.15.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.47.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "business-dev-admin"
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = "dev"
    }
  }
}
