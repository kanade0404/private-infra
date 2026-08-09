terraform {
  backend "s3" {
    bucket         = "private-infra-aws-tfstate"
    key            = "business-prd/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    profile        = "management-admin"
  }
}
