output "api_url_secret_arn" {
  value = aws_secretsmanager_secret.api_url.arn
}

output "paas_token_secret_arn" {
  value = aws_secretsmanager_secret.paas_token.arn
}
