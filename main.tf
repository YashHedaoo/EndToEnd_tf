module "networking" {
  source             = "./modules/networking"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = var.availability_zones
  environment        = var.environment
  tags               = var.tags
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment
  tags        = var.tags
}

module "secrets" {
  source               = "./modules/secrets"
  dynatrace_paas_token = var.dynatrace_paas_token
  dynatrace_url        = var.dynatrace_url
  environment          = var.environment
  tags                 = var.tags
}

module "ecs_cluster" {
  source       = "./modules/ecs-cluster"
  cluster_name = var.cluster_name
  environment  = var.environment
  tags         = var.tags
}

module "ecs_capacity" {
  source                    = "./modules/ecs-capacity"
  ecs_cluster_name          = module.ecs_cluster.cluster_name
  ecs_cluster_id            = module.ecs_cluster.cluster_id
  ecs_instance_profile_name = module.iam.ecs_instance_profile_name
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  security_group_id         = module.networking.ecs_host_sg_id
  instance_type             = var.instance_type
  ami_id                    = var.ami_id
  environment               = var.environment
  tags                      = var.tags

  depends_on = [
    module.ecs_cluster
  ]
}

module "oneagent" {
  source                      = "./modules/oneagent"
  ecs_cluster_id              = module.ecs_cluster.cluster_id
  ecs_cluster_name            = module.ecs_cluster.cluster_name
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.iam.ecs_task_role_arn
  api_url_secret_arn          = module.secrets.api_url_secret_arn
  paas_token_secret_arn       = module.secrets.paas_token_secret_arn
  aws_region                  = var.aws_region
  environment                 = var.environment
  tags                        = var.tags

  # Ensure instances are registered before launching Daemon service
  depends_on = [
    module.ecs_capacity
  ]
}
