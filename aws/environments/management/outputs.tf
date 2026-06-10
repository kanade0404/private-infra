output "organization_id" {
  value = aws_organizations_organization.org.id
}

output "management_account_id" {
  value = aws_organizations_organization.org.master_account_id
}

output "personal_dev_account_id" {
  value = aws_organizations_account.personal_dev.id
}

output "personal_prd_account_id" {
  value = aws_organizations_account.personal_prd.id
}

output "business_dev_account_id" {
  value = aws_organizations_account.business_dev.id
}

output "business_prd_account_id" {
  value = aws_organizations_account.business_prd.id
}

output "sso_start_url" {
  value = var.enable_sso ? "https://${tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0]}.awsapps.com/start" : ""
}

output "tfstate_bucket" {
  value = aws_s3_bucket.tfstate.id
}
