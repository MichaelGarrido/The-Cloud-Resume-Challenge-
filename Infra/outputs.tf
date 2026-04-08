output "site_url" {
  value       = "https://${var.domain_name}"
  description = "Custom domain URL"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.cdn.id
  description = "CloudFront distribution ID"
}
