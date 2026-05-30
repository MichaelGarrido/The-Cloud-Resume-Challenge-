resource "aws_sns_topic" "resume_alerts" {
  count = local.monitoring_enabled ? 1 : 0
  name  = "resume-alerts-${var.environment}"
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = local.monitoring_enabled ? 1 : 0
  topic_arn = aws_sns_topic.resume_alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = local.monitoring_enabled ? 1 : 0
  alarm_name          = "resume-lambda-errors-${var.environment}"
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
    FunctionName = aws_lambda_function.visitor_counter.function_name
  }

  alarm_actions = [aws_sns_topic.resume_alerts[0].arn]
  ok_actions    = [aws_sns_topic.resume_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count               = local.monitoring_enabled ? 1 : 0
  alarm_name          = "resume-lambda-duration-${var.environment}"
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
    FunctionName = aws_lambda_function.visitor_counter.function_name
  }

  alarm_actions = [aws_sns_topic.resume_alerts[0].arn]
  ok_actions    = [aws_sns_topic.resume_alerts[0].arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_invocations" {
  count               = local.monitoring_enabled ? 1 : 0
  alarm_name          = "resume-lambda-invocations-${var.environment}"
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
    FunctionName = aws_lambda_function.visitor_counter.function_name
  }

  alarm_actions = [aws_sns_topic.resume_alerts[0].arn]
  ok_actions    = [aws_sns_topic.resume_alerts[0].arn]
}
