output "ecs_cluster_id" {
  description = "ecs cluster created from terraform-aws-ecs-free-tier project"
  value = aws_ecs_cluster.ecs_cluster.id
}

output "rds_connection_url" {
  description = "rds connection url"
  value = "${aws_db_instance.rds.username}:${aws_db_instance.rds.password}@${aws_db_instance.rds.endpoint}/${aws_db_instance.rds.name}"
}

output "task_role" {
  description = "task role for task_role_arn of aws_ecs_task_definition"
  value = aws_iam_role.task_role_iam_role.arn
}

output "task_execution_role" {
  description = "task execution role for execution_role_arn of aws_ecs_task_definition"
  value = aws_iam_role.task_execution_role_iam_role.arn
}
