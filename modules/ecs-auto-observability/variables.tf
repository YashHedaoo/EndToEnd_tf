variable "oneagent_task_definition_arn" {
  type        = string
  description = "The ARN of the OneAgent task definition to deploy"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "The ARN of the ECS task role"
}

variable "environment" {
  type        = string
  description = "The environment name"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "monitored_clusters" {
  type        = list(string)
  description = "List of ECS cluster names where Dynatrace OneAgent should be deployed."
}

