output "task_definition_arn" {
  value = aws_ecs_task_definition.oneagent.arn
}

output "service_name" {
  value = aws_ecs_service.oneagent.name
}
