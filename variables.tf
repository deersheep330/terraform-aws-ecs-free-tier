variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to be created"
  type = string
  default = "deerpark-ecs"
}

variable "name_prefix" {
  description = "Name prefix of each resources"
  type = string
  default = "deerpark"
}