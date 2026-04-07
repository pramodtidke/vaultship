output "ecr_repository_url" {
  description = "ECR repository URL — use this in docker push commands"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "github_actions_role_arn" {
  description = "ARN to paste into GitHub Secret AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS task logs"
  value       = aws_cloudwatch_log_group.app.name
}
