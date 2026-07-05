locals {
  project_tags = var.project_tag_value != "" ? merge(var.tags, { Project = var.project_tag_value }) : var.tags
}

data "aws_ecs_cluster" "existing" {
  count        = var.is_new_project ? 0 : 1
  cluster_name = var.cluster_name
}

module "networking" {
  count              = var.is_new_project ? 1 : 0
  source             = "./modules/networking"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = var.availability_zones
  environment        = var.environment
  tags               = local.project_tags
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment
  tags        = local.project_tags
}

module "secrets" {
  source               = "./modules/secrets"
  dynatrace_paas_token = var.dynatrace_paas_token
  dynatrace_url        = var.dynatrace_url
  environment          = var.environment
  tags                 = local.project_tags
}

module "ecs_cluster" {
  source              = "./modules/ecs-cluster"
  cluster_name        = var.cluster_name
  create_cluster      = var.is_new_project
  existing_cluster_id = var.is_new_project ? "" : data.aws_ecs_cluster.existing[0].arn
  environment         = var.environment
  tags                = local.project_tags
}

module "ecs_capacity" {
  count                     = var.is_new_project ? 1 : 0
  source                    = "./modules/ecs-capacity"
  ecs_cluster_name          = module.ecs_cluster.cluster_name
  ecs_cluster_id            = module.ecs_cluster.cluster_id
  ecs_instance_profile_name = module.iam.ecs_instance_profile_name
  vpc_id                    = module.networking[0].vpc_id
  private_subnet_ids        = module.networking[0].private_subnet_ids
  security_group_id         = module.networking[0].ecs_host_sg_id
  instance_type             = var.instance_type
  ami_id                    = var.ami_id
  environment               = var.environment
  tags                      = local.project_tags

  depends_on = [
    module.ecs_cluster
  ]
}

module "oneagent" {
  source                        = "./modules/oneagent"
  ecs_cluster_id                = module.ecs_cluster.cluster_id
  ecs_cluster_name              = module.ecs_cluster.cluster_name
  ecs_task_execution_role_arn   = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn             = module.iam.ecs_task_role_arn
  api_url_secret_arn            = module.secrets.api_url_secret_arn
  paas_token_secret_arn         = module.secrets.paas_token_secret_arn
  aws_region                    = var.aws_region
  environment                   = var.environment
  tags                          = local.project_tags
  oneagent_installer_script_url = var.oneagent_installer_script_url
  create_service                = true

  # Ensure instances are registered before launching Daemon service if capacity is deployed
  depends_on = [
    module.ecs_capacity
  ]
}

module "auto_observability" {
  count                        = var.enable_auto_observability ? 1 : 0
  source                       = "./modules/ecs-auto-observability"
  oneagent_task_definition_arn = module.oneagent.task_definition_arn
  ecs_task_execution_role_arn  = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn            = module.iam.ecs_task_role_arn
  environment                  = var.environment
  tags                         = local.project_tags
  monitored_clusters           = var.monitored_clusters
}
