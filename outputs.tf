output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.networking.vpc_id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "oneagent_service_name" {
  description = "The name of the Dynatrace OneAgent Daemon service"
  value       = module.oneagent.service_name
}

output "api_url_secret_arn" {
  description = "The Secrets Manager ARN for Dynatrace API URL"
  value       = module.secrets.api_url_secret_arn
}

output "paas_token_secret_arn" {
  description = "The Secrets Manager ARN for Dynatrace PaaS Token"
  value       = module.secrets.paas_token_secret_arn
}
