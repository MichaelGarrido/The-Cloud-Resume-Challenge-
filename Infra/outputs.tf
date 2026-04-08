output "website_url" {
  value       = "http://${aws_s3_bucket.static_website.bucket}.s3-website-${var.aws_region}.amazonaws.com"
  description = "URL of the static website"
}
