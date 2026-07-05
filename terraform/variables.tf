variable "aws_region" {
  description = "AWS region. Workshop accounts are restricted to us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Base name used for the gateway, runtime, and related resources."
  type        = string
  default     = "virtual-meteorologist"
}

variable "model_id" {
  description = "Bedrock model ID (or inference profile ID) the agent runtime invokes."
  type        = string
  default     = "us.amazon.nova-2-lite-v1:0"
}

variable "cognito_callback_urls" {
  description = "Allowed OAuth callback URLs for the Cognito app client."
  type        = list(string)
  default     = ["https://d84l1y8p4kdic.cloudfront.net"]
}

variable "test_user_username" {
  description = "Username for the workshop test user (Module 1)."
  type        = string
  default     = "AppUser"
}

variable "test_user_email" {
  description = "Email attribute for the workshop test user."
  type        = string
  default     = "AppUser@mycompany.com"
}

variable "test_user_password" {
  description = "Permanent password for the workshop test user. Must satisfy the user pool password policy (8+ chars, upper/lower/number/symbol). Not defaulted so it never ends up committed to version control."
  type        = string
  sensitive   = true
}
