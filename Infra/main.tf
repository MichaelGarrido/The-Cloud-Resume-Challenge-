# Random ID (for unique bucket name)
resource "random_id" "bucket_id" {
  byte_length = 4
}

# S3 Bucket
resource "aws_s3_bucket" "static_website" {
  bucket = "${var.bucket_name}-${random_id.bucket_id.hex}"

  tags = {
    Name        = "Cloud Resume Website"
    Environment = "prod"
  }
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.static_website.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_acm_certificate" "cert" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = ["www.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for private S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  aliases = [
    var.domain_name,
    "www.${var.domain_name}"
  ]

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
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.cert]
}

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

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/${var.website_files_path}", "**/*")

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
