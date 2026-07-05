output "task_definition_arn" {
  value = aws_ecs_task_definition.oneagent.arn
}

output "service_arn" {
  value = var.create_service ? aws_ecs_service.oneagent[0].id : null
}
