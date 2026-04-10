variable "aws_region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
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

variable "alert_email" {
  description = "Email address for CloudWatch/SNS alerts"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to monitor"
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
