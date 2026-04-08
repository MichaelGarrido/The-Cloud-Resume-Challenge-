variable "bucket_name" {
  description = "Unique name for the S3 bucket"
  type        = string
}

variable "website_files_path" {
  description = "Local path to your website files"
  type        = string
  default     = "./website"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
