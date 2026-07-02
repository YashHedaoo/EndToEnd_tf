variable "ecs_cluster_name" {
  type        = string
  description = "The name of the ECS Cluster"
}

variable "ecs_cluster_id" {
  type        = string
  description = "The ID of the ECS Cluster"
}

variable "ecs_instance_profile_name" {
  type        = string
  description = "The name of the IAM instance profile for ECS host instances"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The list of private subnet IDs for the ASG"
}

variable "security_group_id" {
  type        = string
  description = "The Security Group ID for ECS host instances"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for ECS hosts"
  default     = "t3.medium"
}

variable "ami_id" {
  type        = string
  description = "The ECS optimized AMI ID. If empty, the latest is fetched dynamically."
  default     = ""
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
