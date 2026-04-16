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

  filename         = data.archive_file.visitor_counter_zip.output_path
  source_code_hash = data.archive_file.visitor_counter_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.visitor_counter.name
    }
  }
}

# HTTP API Gateway
resource "aws_apigatewayv2_api" "visitor_api" {
  name          = "resume-visitor-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["GET", "OPTIONS"]
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
}

resource "aws_lambda_permission" "allow_apigw_to_invoke_visitor_counter" {
  statement_id  = "AllowAPIGatewayInvokeVisitorCounter-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}
