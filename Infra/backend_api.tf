# Package the Lambda code
data "archive_file" "visitor_counter_zip" {
  type        = "zip"
  source_file = "${path.module}/../Backend/lambda_function.py"
  output_path = "${path.module}/../Backend/lambda_function.zip"
}

# DynamoDB table
resource "aws_dynamodb_table" "visitor_counter" {
  name         = "visitor-counter-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Name        = "visitor-counter-${var.environment}"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# IAM role for Lambda
resource "aws_iam_role" "visitor_counter_lambda_role" {
  name = "visitor-counter-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Lambda logging permissions
resource "aws_iam_role_policy_attachment" "visitor_counter_lambda_basic" {
  role       = aws_iam_role.visitor_counter_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "visitor_counter_lambda_xray" {
  role       = aws_iam_role.visitor_counter_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# DynamoDB access for Lambda
resource "aws_iam_role_policy" "visitor_counter_dynamodb_access" {
  name = "visitor-counter-dynamodb-${var.environment}"
  role = aws_iam_role.visitor_counter_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.visitor_counter.arn
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "visitor_counter" {
  function_name = "resume-visitor-counter-${var.environment}"
  role          = aws_iam_role.visitor_counter_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  filename         = var.visitor_counter_signed_s3_key == null ? data.archive_file.visitor_counter_zip.output_path : null
  source_code_hash = var.visitor_counter_signed_s3_key == null ? data.archive_file.visitor_counter_zip.output_base64sha256 : null
  s3_bucket        = var.visitor_counter_signed_s3_key == null ? null : var.visitor_counter_signed_s3_bucket
  s3_key           = var.visitor_counter_signed_s3_key

  code_signing_config_arn = aws_lambda_code_signing_config.lambda.arn
  memory_size             = 128
  timeout                 = 5
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_counter.name
    }
  }
}

resource "aws_cloudwatch_log_group" "visitor_counter" {
  name              = "/aws/lambda/${aws_lambda_function.visitor_counter.function_name}"
  retention_in_days = 30
}

# HTTP API Gateway
resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "resume-visitor-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type"]
    allow_origins = ["*"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_integration" "visitor_lambda" {
  api_id                 = aws_apigatewayv2_api.visitor_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "visitor_count" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "GET /counter"
  target    = "integrations/${aws_apigatewayv2_integration.visitor_lambda.id}"
}

resource "aws_apigatewayv2_stage" "visitor_default" {
  api_id      = aws_apigatewayv2_api.visitor_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

resource "aws_lambda_permission" "allow_apigw_to_invoke_visitor_counter" {
  statement_id  = "AllowAPIGatewayInvokeVisitorCounter-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}
