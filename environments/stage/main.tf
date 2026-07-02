module "ecs_oneagent_integration" {
  source = "../../"

  dynatrace_url        = var.dynatrace_url
  dynatrace_paas_token = var.dynatrace_paas_token
  aws_region           = var.aws_region
  aws_account_id       = var.aws_account_id
  environment          = "stage"
  instance_type        = var.instance_type
  cluster_name         = var.cluster_name
  ami_id               = var.ami_id
  availability_zones   = var.availability_zones
}
