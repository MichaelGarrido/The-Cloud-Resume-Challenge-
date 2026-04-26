data "archive_file" "chatbot_zip" {
  type        = "zip"
  output_path = "${path.module}/../Backend/chatbot_function.zip"

  source {
    content  = file("${path.module}/../Backend/chatbot_function.py")
    filename = "chatbot_function.py"
  }

  source {
    content  = file("${path.module}/../Backend/chatbot_knowledge.md")
    filename = "chatbot_knowledge.md"
  }
}

resource "aws_iam_role" "chatbot_lambda_role" {
  name = "resume-chatbot-role-${var.environment}"

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

resource "aws_iam_role_policy_attachment" "chatbot_lambda_basic" {
  role       = aws_iam_role.chatbot_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "chatbot" {
  function_name = "resume-chatbot-${var.environment}"
  role          = aws_iam_role.chatbot_lambda_role.arn
  handler       = "chatbot_function.lambda_handler"
  runtime       = "python3.12"

  filename         = var.chatbot_signed_s3_key == null ? data.archive_file.chatbot_zip.output_path : null
  source_code_hash = var.chatbot_signed_s3_key == null ? data.archive_file.chatbot_zip.output_base64sha256 : null
  s3_bucket        = var.chatbot_signed_s3_key == null ? null : var.chatbot_signed_s3_bucket
  s3_key           = var.chatbot_signed_s3_key

  code_signing_config_arn = aws_lambda_code_signing_config.lambda.arn
  memory_size             = 256
  timeout                 = 15

  environment {
    variables = {
      OPENAI_API_KEY = var.openai_api_key
      OPENAI_MODEL   = var.openai_model
    }
  }
}

resource "aws_cloudwatch_log_group" "chatbot" {
  name              = "/aws/lambda/${aws_lambda_function.chatbot.function_name}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_integration" "chatbot_lambda" {
  api_id                 = aws_apigatewayv2_api.visitor_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.chatbot.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "chatbot" {
  api_id    = aws_apigatewayv2_api.visitor_api.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.chatbot_lambda.id}"
}

resource "aws_lambda_permission" "allow_apigw_to_invoke_chatbot" {
  statement_id  = "AllowAPIGatewayInvokeChatbot-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*"
}
