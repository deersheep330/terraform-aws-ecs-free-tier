output "task_role" {
  description = "task role for task_role_arn of aws_ecs_task_definition"
  value = aws_iam_role.task_role_iam_role.arn
}

output "task_execution_role" {
  description = "task execution role for execution_role_arn of aws_ecs_task_definition"
  value = aws_iam_role.task_execution_role_iam_role.arn
}
