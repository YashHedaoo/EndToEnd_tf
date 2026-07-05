variable "ecs_cluster_id" {
  type        = string
  description = "The ID of the ECS cluster"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ECS cluster"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "The ARN of the ECS task role"
}

variable "api_url_secret_arn" {
  type        = string
  description = "The Secrets Manager ARN for Dynatrace API URL"
}

variable "paas_token_secret_arn" {
  type        = string
  description = "The Secrets Manager ARN for Dynatrace PaaS Token"
}

variable "network_zone" {
  type        = string
  description = "Dynatrace network zone (optional)"
  default     = ""
}

variable "aws_region" {
  type        = string
  description = "The AWS region for logging"
}

variable "environment" {
  type        = string
  description = "The environment name"
}

variable "oneagent_image" {
  type        = string
  description = "OneAgent container image"
  default     = "registry.dynatrace.com/linux/oneagent:latest"
}

variable "log_group_name" {
  type        = string
  description = "Name of the CloudWatch log group for OneAgent"
  default     = "dynatrace-oneagent"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "oneagent_installer_script_url" {
  type        = string
  description = "The Dynatrace OneAgent installer script URL"
  default     = ""
}

variable "create_service" {
  type        = bool
  description = "Whether to create the ECS service for OneAgent"
  default     = true
}

