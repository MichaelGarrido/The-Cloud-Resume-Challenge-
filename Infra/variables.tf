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
