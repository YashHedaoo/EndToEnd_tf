output "vpc_id" {
  description = "The ID of the created VPC"
  value       = var.is_new_project ? module.networking[0].vpc_id : null
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "auto_observability_lambda_arn" {
  description = "The ARN of the Lambda Auto-Observability Controller"
  value       = var.enable_auto_observability ? module.auto_observability[0].lambda_function_arn : null
}

output "api_url_secret_arn" {
  description = "The Secrets Manager ARN for Dynatrace API URL"
  value       = module.secrets.api_url_secret_arn
}

output "paas_token_secret_arn" {
  description = "The Secrets Manager ARN for Dynatrace PaaS Token"
  value       = module.secrets.paas_token_secret_arn
}

output "oneagent_task_definition_arn" {
  description = "The ARN of the Dynatrace OneAgent task definition"
  value       = module.oneagent.task_definition_arn
}

