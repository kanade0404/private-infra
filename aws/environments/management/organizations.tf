resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["sso.amazonaws.com"]
  feature_set                   = "ALL"
  enabled_policy_types          = ["SERVICE_CONTROL_POLICY"]
}

resource "aws_organizations_organizational_unit" "personal" {
  name      = "Personal"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "business" {
  name      = "Business"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "personal_dev" {
  name              = "personal-dev"
  email             = "${var.account_email_prefix}+aws-personal-dev@${var.account_email_domain}"
  parent_id         = aws_organizations_organizational_unit.personal.id
  close_on_deletion = false
  role_name         = "OrganizationAccountAccessRole"

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "personal_prd" {
  name              = "personal-prd"
  email             = "${var.account_email_prefix}+aws-personal-prd@${var.account_email_domain}"
  parent_id         = aws_organizations_organizational_unit.personal.id
  close_on_deletion = false
  role_name         = "OrganizationAccountAccessRole"

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "business_dev" {
  name              = "business-dev"
  email             = "${var.account_email_prefix}+aws-business-dev@${var.account_email_domain}"
  parent_id         = aws_organizations_organizational_unit.business.id
  close_on_deletion = false
  role_name         = "OrganizationAccountAccessRole"

  lifecycle {
    ignore_changes = [role_name]
  }
}

resource "aws_organizations_account" "business_prd" {
  name              = "business-prd"
  email             = "${var.account_email_prefix}+aws-business-prd@${var.account_email_domain}"
  parent_id         = aws_organizations_organizational_unit.business.id
  close_on_deletion = false
  role_name         = "OrganizationAccountAccessRole"

  lifecycle {
    ignore_changes = [role_name]
  }
}
