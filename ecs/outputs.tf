output "ecs_cluster_id" {
  description = "ecs cluster created from terraform-aws-ecs-free-tier project"
  value = aws_ecs_cluster.ecs_cluster.id
}

output "ecs_alb_dns_name" {
  value = aws_alb.ecs_alb.dns_name
}
