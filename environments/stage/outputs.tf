output "vpc_id" {
  description = "The ID of the created VPC"
  value       = module.ecs_oneagent_integration.vpc_id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs_oneagent_integration.ecs_cluster_name
}

output "oneagent_service_name" {
  description = "The name of the Dynatrace OneAgent Daemon service"
  value       = module.ecs_oneagent_integration.oneagent_service_name
}
