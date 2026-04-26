# Random ID (for unique bucket & OAC names)
resource "random_id" "bucket_id" {
  byte_length = 4
}

locals {
  env                 = var.environment
  is_prod             = var.environment == "prod"
  has_route53_zone_id = length(trimspace(var.route53_zone_id)) > 0
  signer_env_slug     = substr(replace(var.environment, "/[^A-Za-z0-9]/", ""), 0, 20)
  signer_name_prefix  = substr("resumelambda${local.signer_env_slug}", 0, 38)
}

# S3 Bucket
resource "aws_s3_bucket" "static_website" {
  bucket = "${var.bucket_name}-${var.environment}-${random_id.bucket_id.hex}"

  tags = {
    Name        = "Cloud Resume Website"
    Environment = var.environment
  }
}

# Block ALL public access (CloudFront only)
resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.static_website.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Get Route53 zone
data "aws_route53_zone" "main" {
  count        = local.is_prod ? 1 : 0
  name         = local.has_route53_zone_id ? null : var.domain_name
  zone_id      = local.has_route53_zone_id ? var.route53_zone_id : null
  private_zone = false
}

# ACM Certificate (prod only, must be in us-east-1 for CloudFront)
resource "aws_acm_certificate" "cert" {
  count                     = local.is_prod ? 1 : 0
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = ["www.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 validation records (prod only)
resource "aws_route53_record" "cert_validation" {
  for_each = local.is_prod ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id         = data.aws_route53_zone.main[0].zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

# Validate cert (prod only)
resource "aws_acm_certificate_validation" "cert" {
  count                   = local.is_prod ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# CloudFront OAC
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.bucket_name}-${var.environment}-${random_id.bucket_id.hex}-oac"
  description                       = "OAC for private S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  aliases = local.is_prod ? [
    var.domain_name,
    "www.${var.domain_name}"
  ] : []

  origin {
    domain_name              = aws_s3_bucket.static_website.bucket_regional_domain_name
    origin_id                = "s3-origin-${aws_s3_bucket.static_website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin-${aws_s3_bucket.static_website.id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = local.is_prod ? aws_acm_certificate_validation.cert[0].certificate_arn : null
    ssl_support_method             = local.is_prod ? "sni-only" : null
    minimum_protocol_version       = local.is_prod ? "TLSv1.2_2021" : "TLSv1"
    cloudfront_default_certificate = local.is_prod ? false : true
  }

}

# Allow ONLY CloudFront to access S3
resource "aws_s3_bucket_policy" "allow_cloudfront_only" {
  bucket = aws_s3_bucket.static_website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.static_website.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.cdn]
}

# Root domain → CloudFront (prod only)
resource "aws_route53_record" "root" {
  count           = local.is_prod ? 1 : 0
  zone_id         = data.aws_route53_zone.main[0].zone_id
  name            = var.domain_name
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# www domain → CloudFront (prod only)
resource "aws_route53_record" "www" {
  count           = local.is_prod ? 1 : 0
  zone_id         = data.aws_route53_zone.main[0].zone_id
  name            = "www.${var.domain_name}"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# Upload website files
resource "aws_s3_object" "website_files" {
  for_each = {
    for file in fileset("${path.module}/${var.website_files_path}", "**/*") :
    file => file if file != "index.html"
  }
  bucket = aws_s3_bucket.static_website.id
  key    = each.value
  source = "${path.module}/${var.website_files_path}/${each.value}"

  source_hash = filemd5("${path.module}/${var.website_files_path}/${each.value}")

  content_type = lookup(
    {
      html = "text/html"
      css  = "text/css"
      js   = "application/javascript"
      png  = "image/png"
      jpg  = "image/jpeg"
      jpeg = "image/jpeg"
      gif  = "image/gif"
      svg  = "image/svg+xml"
      ico  = "image/x-icon"
      json = "application/json"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "binary/octet-stream"
  )
}


resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.static_website.id
  key    = "index.html"

  content = templatefile("${path.module}/../Frontend/index.html.tpl", {
    api_url = aws_apigatewayv2_api.visitor_api.api_endpoint
  })

  content_type = "text/html"
}
