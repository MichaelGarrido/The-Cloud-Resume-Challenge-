resource "aws_sns_topic" "resume_alerts" {
  name = "resume-alerts"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.resume_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "resume-lambda-errors"
  alarm_description   = "Alert when Lambda reports one or more errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = var.lambda_error_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.resume_alerts.arn]
  ok_actions    = [aws_sns_topic.resume_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "resume-lambda-duration"
  alarm_description   = "Alert when Lambda average duration is too high"
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  threshold           = var.lambda_duration_threshold_ms
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.resume_alerts.arn]
  ok_actions    = [aws_sns_topic.resume_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_invocations" {
  alarm_name          = "resume-lambda-invocations"
  alarm_description   = "Alert when Lambda invocations spike unexpectedly"
  namespace           = "AWS/Lambda"
  metric_name         = "Invocations"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = var.lambda_invocation_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.resume_alerts.arn]
  ok_actions    = [aws_sns_topic.resume_alerts.arn]
}
