terraform {
  required_version = "1.15.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.47.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "business-prd-admin"
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = "prd"
    }
  }
}
