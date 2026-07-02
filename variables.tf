variable "dynatrace_url" {
  type        = string
  description = "The Dynatrace Environment URL (e.g., https://xyz123.live.dynatrace.com)"
}

variable "dynatrace_paas_token" {
  type        = string
  description = "The Dynatrace PaaS/Installer Token with download permission for the OneAgent script"
  sensitive   = true
}

variable "aws_account_id" {
  type        = string
  description = "The AWS Account ID of the target account being monitored"
  default     = ""
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy monitoring infrastructure and configurations"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, test, stage)"
}

variable "cluster_name" {
  type        = string
  description = "The name of the ECS cluster to create"
  default     = "ecs-oneagent-cluster"
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type for the ECS hosts"
  default     = "t3.medium"
}

variable "ami_id" {
  type        = string
  description = "The ECS optimized AMI ID. If empty, the latest is fetched dynamically."
  default     = ""
}

variable "availability_zones" {
  type        = list(string)
  description = "The availability zones to deploy into"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to all resources created"
  default = {
    ManagedBy = "Terraform"
    Project   = "Dynatrace-ECS-OneAgent-Daemon"
  }
}
