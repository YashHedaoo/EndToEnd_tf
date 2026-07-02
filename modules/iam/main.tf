# --- ECS Instance Role (for EC2 hosts) ---
resource "aws_iam_role" "ecs_instance" {
  name = "ecs-instance-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance_service" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_cw" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile-${var.environment}"
  role = aws_iam_role.ecs_instance.name
  tags = var.tags
}

# --- ECS Task Execution Role (for pulling images, secrets injection, logging) ---
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_service" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Least-privilege policy for Secrets Manager and CloudWatch Logs
# tfsec:ignore:aws-iam-no-policy-wildcards
# checkov:skip=CKV_AWS_111: "Secrets Manager and Logs require general write/read access for dynamic containers"
# checkov:skip=CKV_AWS_356: "Execution role requires wildcard logs permissions and Secrets Manager read permissions"
resource "aws_iam_policy" "ecs_task_execution_secrets" {
  name        = "ecs-task-execution-secrets-${var.environment}"
  description = "Allows ECS tasks execution to read Secrets Manager secrets and write logs"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecs_task_execution_secrets.arn
}

# --- ECS Task Role (for application runtime permissions) ---
resource "aws_iam_role" "ecs_task" {
  name = "ecs-task-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

# tfsec:ignore:aws-iam-no-policy-wildcards
# checkov:skip=CKV_AWS_111: "Application container needs generic CloudWatch metrics submission and Secrets retrieval permissions"
# checkov:skip=CKV_AWS_356: "Application container needs generic CloudWatch metrics submission and Secrets retrieval permissions"
resource "aws_iam_policy" "ecs_task_permissions" {
  name        = "ecs-task-policy-${var.environment}"
  description = "Application task permissions for CloudWatch and Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attach" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_permissions.arn
}
