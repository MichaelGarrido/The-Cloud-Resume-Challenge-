output "site_url" {
  value = local.is_prod ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "visitor_api_url" {
  value = aws_apigatewayv2_api.visitor_api.api_endpoint
}

output "visitor_counter_lambda_name" {
  value = aws_lambda_function.visitor_counter.function_name
}

output "visitor_counter_table_name" {
  value = aws_dynamodb_table.visitor_counter.name
}

output "lambda_signing_profile_name" {
  value = aws_signer_signing_profile.lambda.name
}

output "lambda_signing_artifacts_bucket" {
  value = aws_s3_bucket.lambda_signing_artifacts.bucket
}
