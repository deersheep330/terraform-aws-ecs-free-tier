output "ecs_cluster_id" {
  description = "ecs cluster created from terraform-aws-ecs-free-tier project"
  value = aws_ecs_cluster.ecs_cluster.id
}
