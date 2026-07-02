output "asg_arn" {
  value = aws_autoscaling_group.ecs.arn
}

output "asg_name" {
  value = aws_autoscaling_group.ecs.name
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.ecs_cp.name
}
