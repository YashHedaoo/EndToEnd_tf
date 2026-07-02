variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster"
  default     = "ecs-oneagent-cluster"
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
