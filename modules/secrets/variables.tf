variable "dynatrace_paas_token" {
  type        = string
  description = "Dynatrace PaaS Token"
  sensitive   = true
}

variable "dynatrace_url" {
  type        = string
  description = "Dynatrace Environment URL"
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
