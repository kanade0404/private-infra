data "aws_ssoadmin_instances" "this" {
  count = var.enable_sso ? 1 : 0
}

locals {
  sso_instance_arn  = var.enable_sso ? tolist(data.aws_ssoadmin_instances.this[0].arns)[0] : ""
  identity_store_id = var.enable_sso ? tolist(data.aws_ssoadmin_instances.this[0].identity_store_ids)[0] : ""
}

# SSO ユーザー
resource "aws_identitystore_user" "admin" {
  count             = var.enable_sso ? 1 : 0
  identity_store_id = local.identity_store_id
  display_name      = var.sso_user_display_name
  user_name         = "admin"

  name {
    given_name  = var.sso_user_given_name
    family_name = var.sso_user_family_name
  }

  emails {
    value   = var.sso_user_email
    primary = true
  }
}

# Admins グループ
resource "aws_identitystore_group" "admins" {
  count             = var.enable_sso ? 1 : 0
  identity_store_id = local.identity_store_id
  display_name      = "Admins"
  description       = "Full administrator access"
}

resource "aws_identitystore_group_membership" "admin" {
  count             = var.enable_sso ? 1 : 0
  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.admins[0].group_id
  member_id         = aws_identitystore_user.admin[0].user_id
}

# Permission Set: AdministratorAccess
resource "aws_ssoadmin_permission_set" "admin" {
  count            = var.enable_sso ? 1 : 0
  name             = "AdministratorAccess"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
  description      = "Full administrator access"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  count              = var.enable_sso ? 1 : 0
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin[0].arn
}

# Permission Set: ReadOnlyAccess
resource "aws_ssoadmin_permission_set" "readonly" {
  count            = var.enable_sso ? 1 : 0
  name             = "ReadOnlyAccess"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
  description      = "Read-only access"
}

resource "aws_ssoadmin_managed_policy_attachment" "readonly" {
  count              = var.enable_sso ? 1 : 0
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.readonly[0].arn
}

# アカウント割り当て: Admins → AdministratorAccess → 全アカウント
resource "aws_ssoadmin_account_assignment" "admin_management" {
  count              = var.enable_sso ? 1 : 0
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin[0].arn
  principal_id       = aws_identitystore_group.admins[0].group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_organization.org.master_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "admin_personal_dev" {
  count              = var.enable_sso ? 1 : 0
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin[0].arn
  principal_id       = aws_identitystore_group.admins[0].group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.personal_dev.id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "admin_personal_prd" {
  count              = var.enable_sso ? 1 : 0
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin[0].arn
  principal_id       = aws_identitystore_group.admins[0].group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.personal_prd.id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "admin_business_dev" {
  count              = var.enable_sso ? 1 : 0
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin[0].arn
  principal_id       = aws_identitystore_group.admins[0].group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.business_dev.id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "admin_business_prd" {
  count              = var.enable_sso ? 1 : 0
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin[0].arn
  principal_id       = aws_identitystore_group.admins[0].group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.business_prd.id
  target_type        = "AWS_ACCOUNT"
}
