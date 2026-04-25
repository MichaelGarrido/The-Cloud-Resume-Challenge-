resource "aws_s3_bucket" "lambda_signing_artifacts" {
  bucket = "${var.bucket_name}-${var.environment}-lambda-signing-${random_id.bucket_id.hex}"

  tags = {
    Name        = "lambda-signing-artifacts-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_signing_artifacts" {
  bucket                  = aws_s3_bucket.lambda_signing_artifacts.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "lambda_signing_artifacts" {
  bucket = aws_s3_bucket.lambda_signing_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lambda_signing_artifacts" {
  bucket = aws_s3_bucket.lambda_signing_artifacts.id

  rule {
    id     = "expire-signed-artifacts"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_signer_signing_profile" "lambda" {
  name_prefix = "resume-lambda-${var.environment}-"
  platform_id = "AWSLambda-SHA384-ECDSA"

  signature_validity_period {
    value = 5
    type  = "YEARS"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lambda_code_signing_config" "lambda" {
  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.lambda.version_arn
    ]
  }

  policies {
    untrusted_artifact_on_deployment = var.lambda_code_signing_policy
  }

  description = "Require AWS Signer signatures for resume Lambda packages."
}
