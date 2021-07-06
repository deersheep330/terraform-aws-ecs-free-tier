variable "name_prefix" {
  description = "Name prefix of each resources"
  type = string
  default = "deerpark"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to be created"
  type = string
  default = "deerpark-ecs"
}

variable "ecr_repos" {
  description = "List of ecr repositories to be created"
  type = list(string)
  default = [ "rent", "stock", "booking", "stock-frontend" ]
}