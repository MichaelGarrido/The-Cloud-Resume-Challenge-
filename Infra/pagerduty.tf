resource "aws_iam_role" "pagerduty_notifier_lambda_role" {
  name = "resume-pagerduty-notifier-role-${var.environment}"

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
  role       = aws_iam_role.pagerduty_notifier_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "pagerduty_notifier" {
  function_name = "resume-pagerduty-notifier-${var.environment}"
  role          = aws_iam_role.pagerduty_notifier_lambda_role.arn
  handler       = "pagerduty_notifier.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/../Backend/pagerduty_notifier.zip"
  source_code_hash = filebase64sha256("${path.module}/../Backend/pagerduty_notifier.zip")

  environment {
    variables = {
      PAGERDUTY_KEY = var.pagerduty_integration_key
      PAGERDUTY_URL = var.pagerduty_url
    }
  }
}


resource "aws_sns_topic_subscription" "pagerduty_lambda" {
  topic_arn = aws_sns_topic.resume_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.pagerduty_notifier.arn
}

resource "aws_lambda_permission" "allow_sns_to_invoke_pagerduty_lambda" {
  statement_id  = "AllowExecutionFromSNSPagerDuty"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pagerduty_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.resume_alerts.arn
}
