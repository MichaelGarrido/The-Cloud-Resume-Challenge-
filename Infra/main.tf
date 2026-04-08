# S3 Bucket
resource "aws_s3_bucket" "static_website" {
  bucket = var.bucket_name

  tags = {
    Name        = "Cloud Resume Website"
    Environment = "dev"
  }
}

# Keep ACLs blocked, but allow public bucket policy
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.static_website.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# Bucket Policy to allow public read
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.static_website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = ["arn:aws:s3:::${aws_s3_bucket.static_website.bucket}/*"]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

# Configure S3 bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Upload website files
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/${var.website_files_path}", "**/*")

  bucket = aws_s3_bucket.static_website.id
  key    = each.value
  source = "${path.module}/${var.website_files_path}/${each.value}"

  content_type = lookup(
    {
      html = "text/html",
      css  = "text/css",
      js   = "application/javascript",
      png  = "image/png",
      jpg  = "image/jpeg",
      jpeg = "image/jpeg",
      gif  = "image/gif",
      svg  = "image/svg+xml"
    },
    split(".", each.value)[length(split(".", each.value)) - 1],
    "binary/octet-stream"
  )
}
