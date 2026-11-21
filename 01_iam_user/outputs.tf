output "iam_user_name" {
  description = "Name of the IAM user created in this example."
  value       = aws_iam_user.tuser.name
}

output "iam_user_console_sign_in_url" {
  description = "AWS console sign-in URL for tuser."
  value       = "https://${var.aws_account_id}.signin.aws.amazon.com/console"
}

output "iam_user_console_password" {
  description = "Generated console password for tuser."
  value       = aws_iam_user_login_profile.tuser.password
  sensitive   = true
}
