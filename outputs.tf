output "ecs_cluster_id" {
  description = "ecs cluster created from terraform-aws-ecs-free-tier project"
  value = module.ecs.ecs_cluster_id
}

output "rds_connection_url" {
  description = "rds connection url"
  value = module.rds.rds_connection_url
  sensitive = true
}

output "redis_host" {
  description = "redis host"
  value = module.redis.redis_host
  sensitive = true
}

output "task_role" {
  description = "task role for task_role_arn of aws_ecs_task_definition"
  value = module.task_execution_role.task_role
}

output "task_execution_role" {
  description = "task execution role for execution_role_arn of aws_ecs_task_definition"
  value = module.task_execution_role.task_execution_role
} 

output "alb_dns_name" {
  description = "alb dns name for accessing web frontend"
  value = module.ecs.alb_dns_name
}