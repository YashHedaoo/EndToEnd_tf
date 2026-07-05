# checkov:skip=CKV_AWS_338: "OneAgent log group requires standard retention for monitoring daemon"
resource "aws_cloudwatch_log_group" "oneagent" {
  name              = "/ecs/${var.log_group_name}-${var.environment}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_ecs_task_definition" "oneagent" {
  family                   = "dynatrace-oneagent-${var.environment}"
  requires_compatibilities = ["EC2"]
  network_mode             = "host"
  pid_mode                 = "host"
  ipc_mode                 = "host"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name       = "dynatrace-oneagent"
      image      = var.oneagent_image
      essential  = true
      privileged = true

      secrets = [
        {
          name      = "DT_API_URL"
          valueFrom = var.api_url_secret_arn
        },
        {
          name      = "DT_PAAS_TOKEN"
          valueFrom = var.paas_token_secret_arn
        }
      ]

      environment = [
        {
          name  = "DT_NETWORK_ZONE"
          value = var.network_zone
        },
        {
          name  = "DT_CLUSTER_ID"
          value = var.ecs_cluster_name
        },
        {
          name  = "ONEAGENT_INSTALLER_SCRIPT_URL"
          value = var.oneagent_installer_script_url
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "host-root"
          containerPath = "/mnt/root"
          readOnly      = false
        },
        {
          sourceVolume  = "host-proc"
          containerPath = "/proc"
          readOnly      = false
        },
        {
          sourceVolume  = "host-docker"
          containerPath = "/var/lib/docker"
          readOnly      = false
        },
        {
          sourceVolume  = "host-sys"
          containerPath = "/sys"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.oneagent.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "oneagent"
        }
      }
    }
  ])

  volume {
    name      = "host-root"
    host_path = "/"
  }

  volume {
    name      = "host-proc"
    host_path = "/proc"
  }

  volume {
    name      = "host-docker"
    host_path = "/var/lib/docker"
  }

  volume {
    name      = "host-sys"
    host_path = "/sys"
  }

  tags = var.tags
}

resource "aws_ecs_service" "oneagent" {
  count               = var.create_service ? 1 : 0
  name                = "dynatrace-oneagent-${var.environment}"
  cluster             = var.ecs_cluster_id
  task_definition     = aws_ecs_task_definition.oneagent.arn
  scheduling_strategy = "DAEMON"
  launch_type         = "EC2"

  tags = var.tags
}
