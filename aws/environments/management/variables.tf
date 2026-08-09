variable "AWS_ACCESS_KEY_ID" {
  type      = string
  sensitive = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  type      = string
  sensitive = true
}

variable "sso_user_display_name" {
  type        = string
  description = "SSO ユーザーの表示名"
}

variable "sso_user_given_name" {
  type        = string
  description = "SSO ユーザーの名"
}

variable "sso_user_family_name" {
  type        = string
  description = "SSO ユーザーの姓"
}

variable "sso_user_email" {
  type        = string
  description = "SSO ユーザーのメールアドレス"
}

variable "account_email_prefix" {
  type        = string
  description = "メンバーアカウント用メールのプレフィックス（例: yourname）。yourname+aws-personal-dev@gmail.com のように使われる"
}


variable "account_email_domain" {
  type        = string
  description = "メンバーアカウント用メールのドメイン（例: gmail.com）"
}

variable "enable_sso" {
  type        = bool
  description = "IAM Identity Center が有効化済みの場合に true にする"
  default     = false
}
