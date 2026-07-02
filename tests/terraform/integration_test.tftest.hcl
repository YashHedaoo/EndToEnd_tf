# Mock the AWS provider to run tests offline/without credentials
mock_provider "aws" {}

# Override the dynamic SSM parameter data source call for ecs optimized AMI
override_data {
  target = module.ecs_capacity.data.aws_ssm_parameter.ecs_optimized_ami
  values = {
    value = "ami-1234567890abcdef0"
  }
}

variables {
  dynatrace_url        = "https://abc12345.live.dynatrace.com"
  dynatrace_paas_token = "dt0c01.test.paas"
  aws_account_id       = "123456789012"
  aws_region           = "us-east-1"
  cluster_name         = "ecs-oneagent-cluster"
  instance_type        = "t3.medium"
  environment          = "dev"
}

run "validate_ecs_cluster" {
  command = plan

  assert {
    condition     = module.ecs_cluster.cluster_name == "ecs-oneagent-cluster-dev"
    error_message = "ECS cluster name format did not match expected value"
  }
}

run "validate_iam_configuration" {
  command = plan

  assert {
    condition     = module.iam.ecs_instance_profile_name == "ecs-instance-profile-dev"
    error_message = "ECS IAM instance profile name did not match expected value"
  }
}

run "validate_oneagent_task_def" {
  command = plan

  assert {
    condition     = module.oneagent.service_name == "dynatrace-oneagent-dev"
    error_message = "OneAgent ECS Service name did not match expected DAEMON service name"
  }
}
