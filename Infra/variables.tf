variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string

  validation {
    condition     = length(trimspace(var.bucket_name)) > 0
    error_message = "bucket_name cannot be empty. Set the BUCKET_NAME GitHub Actions variable."
  }
}

variable "website_files_path" {
  description = "Local path to website files"
  type        = string
  default     = "../Frontend"
}

variable "domain_name" {
  description = "Your root domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID to use when multiple public zones match domain_name"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for CloudWatch/SNS alerts"
  type        = string
}

variable "lambda_error_threshold" {
  description = "Alarm if Lambda errors are >= this value"
  type        = number
  default     = 1
}

variable "lambda_duration_threshold_ms" {
  description = "Alarm if Lambda average duration exceeds this many ms"
  type        = number
  default     = 2000
}

variable "lambda_invocation_threshold" {
  description = "Alarm if Lambda invocations exceed this value in one period"
  type        = number
  default     = 100
}

variable "pagerduty_integration_key" {
  type      = string
  sensitive = true
}

variable "pagerduty_url" {
  type      = string
  sensitive = true
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "visitor_counter_signed_s3_bucket" {
  description = "S3 bucket containing the signed visitor counter Lambda package"
  type        = string
  default     = null
}

variable "visitor_counter_signed_s3_key" {
  description = "S3 key for the signed visitor counter Lambda package"
  type        = string
  default     = null
}

variable "pagerduty_notifier_signed_s3_bucket" {
  description = "S3 bucket containing the signed PagerDuty notifier Lambda package"
  type        = string
  default     = null
}

variable "pagerduty_notifier_signed_s3_key" {
  description = "S3 key for the signed PagerDuty notifier Lambda package"
  type        = string
  default     = null
}

variable "lambda_code_signing_policy" {
  description = "How Lambda handles unsigned or invalidly signed deployment packages"
  type        = string
  default     = "Enforce"

  validation {
    condition     = contains(["Enforce", "Warn"], var.lambda_code_signing_policy)
    error_message = "lambda_code_signing_policy must be Enforce or Warn."
  }
}

variable "openai_api_key" {
  description = "OpenAI API key for the portfolio chatbot"
  type        = string
  sensitive   = true
}

variable "openai_model" {
  description = "OpenAI model used by the portfolio chatbot"
  type        = string
  default     = "gpt-5-mini"
}

variable "chatbot_signed_s3_bucket" {
  description = "S3 bucket containing the signed chatbot Lambda package"
  type        = string
  default     = null
}

variable "chatbot_signed_s3_key" {
  description = "S3 key for the signed chatbot Lambda package"
  type        = string
  default     = null
}
