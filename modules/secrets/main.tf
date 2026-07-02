# tfsec:ignore:aws-ssm-secret-use-customer-key
# checkov:skip=CKV_AWS_149: "Defaults to standard Secrets Manager default KMS key encryption which is sufficient"
resource "aws_secretsmanager_secret" "api_url" {
  name                    = "dynatrace-api-url-${var.environment}"
  description             = "Dynatrace API URL for ${var.environment}"
  recovery_window_in_days = 0 # Force delete immediately during teardown/tests
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "api_url" {
  secret_id     = aws_secretsmanager_secret.api_url.id
  secret_string = var.dynatrace_url
}

# tfsec:ignore:aws-ssm-secret-use-customer-key
# checkov:skip=CKV_AWS_149: "Defaults to standard Secrets Manager default KMS key encryption which is sufficient"
resource "aws_secretsmanager_secret" "paas_token" {
  name                    = "dynatrace-paas-token-${var.environment}"
  description             = "Dynatrace PaaS/Installer Token for ${var.environment}"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "paas_token" {
  secret_id     = aws_secretsmanager_secret.paas_token.id
  secret_string = var.dynatrace_paas_token
}
