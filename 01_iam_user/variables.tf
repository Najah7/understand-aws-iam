variable "aws_profile" {
  description = "AWS CLI profile used by Terraform. Configure it with credentials for the intended account."
  type        = string
  default     = "terraform"
}

variable "aws_region" {
  description = "AWS region used for all resources."
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_account_id" {
  description = "AWS account allowed to receive changes from this configuration."
  type        = string
}
