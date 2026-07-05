data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/src/lambda_function.zip"
}

# checkov:skip=CKV_AWS_116: "Dead letter queue not required for scheduler sync Lambda"
# checkov:skip=CKV_AWS_117: "VPC not required as Lambda only communicates with AWS ECS API endpoint"
# checkov:skip=CKV_AWS_272: "Code-signing not required for deployment wrapper automation"
resource "aws_lambda_function" "auto_observability" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ecs-auto-observability-${var.environment}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      ENVIRONMENT                  = var.environment
      ONEAGENT_TASK_DEFINITION_ARN = var.oneagent_task_definition_arn
      MONITORED_CLUSTERS           = join(",", var.monitored_clusters)
    }
  }

  tags = var.tags
}

# checkov:skip=CKV_AWS_338: "Retention of 7 days is configured which is standard for short lived Lambdas"
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/ecs-auto-observability-${var.environment}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_iam_role" "lambda_exec" {
  name = "ecs-auto-observability-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "lambda" {
  name        = "ecs-auto-observability-lambda-policy-${var.environment}"
  description = "IAM policy for ECS Auto-Observability Lambda Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:CreateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          var.ecs_task_execution_role_arn,
          var.ecs_task_role_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_cloudwatch_event_rule" "scheduler" {
  name                = "ecs-auto-observability-schedule-${var.environment}"
  description         = "Periodic trigger for Dynatrace OneAgent auto-observability controller"
  schedule_expression = "rate(15 minutes)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.scheduler.name
  target_id = "TriggerEcsAutoObservabilityLambda"
  arn       = aws_lambda_function.auto_observability.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_observability.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduler.arn
}
