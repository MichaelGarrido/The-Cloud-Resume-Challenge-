data "archive_file" "pagerduty_notifier_zip" {
  type        = "zip"
  source_file = "${path.module}/../Backend/pagerduty_notifier.py"
  output_path = "${path.module}/../Backend/pagerduty_notifier.zip"
}

resource "aws_iam_role" "pagerduty_notifier_lambda_role" {
  count = local.pagerduty_enabled ? 1 : 0
  name  = "resume-pagerduty-notifier-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pagerduty_notifier_basic" {
  count      = local.pagerduty_enabled ? 1 : 0
  role       = aws_iam_role.pagerduty_notifier_lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "pagerduty_notifier" {
  depends_on = [aws_lambda_code_signing_config.lambda]

  count         = local.pagerduty_enabled ? 1 : 0
  function_name = "resume-pagerduty-notifier-${var.environment}"
  role          = aws_iam_role.pagerduty_notifier_lambda_role[0].arn
  handler       = "pagerduty_notifier.lambda_handler"
  runtime       = "python3.12"

  filename          = var.pagerduty_notifier_signed_s3_key == null ? data.archive_file.pagerduty_notifier_zip.output_path : null
  source_code_hash  = var.pagerduty_notifier_signed_s3_key == null ? data.archive_file.pagerduty_notifier_zip.output_base64sha256 : null
  s3_bucket         = var.pagerduty_notifier_signed_s3_key == null ? null : var.pagerduty_notifier_signed_s3_bucket
  s3_key            = var.pagerduty_notifier_signed_s3_key
  s3_object_version = var.pagerduty_notifier_signed_s3_object_version

  code_signing_config_arn = aws_lambda_code_signing_config.lambda.arn
  memory_size             = 128
  timeout                 = 10

  environment {
    variables = {
      PAGERDUTY_KEY = var.pagerduty_integration_key
      PAGERDUTY_URL = var.pagerduty_url
    }
  }
}

resource "aws_cloudwatch_log_group" "pagerduty_notifier" {
  count             = local.pagerduty_enabled ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.pagerduty_notifier[0].function_name}"
  retention_in_days = local.log_retention_days
}


resource "aws_sns_topic_subscription" "pagerduty_lambda" {
  count     = local.pagerduty_enabled ? 1 : 0
  topic_arn = aws_sns_topic.resume_alerts[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.pagerduty_notifier[0].arn
}

resource "aws_lambda_permission" "allow_sns_to_invoke_pagerduty_lambda" {
  count         = local.pagerduty_enabled ? 1 : 0
  statement_id  = "AllowExecutionFromSNSPagerDuty"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pagerduty_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.resume_alerts[0].arn
}
