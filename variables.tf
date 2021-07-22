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

variable "certificate_arn" {
  description = "the aws acm certificate arn created from AWS Certificate Manager"
  type = string
  default = "arn:aws:acm:us-east-2:696324379330:certificate/1e9e7e02-e7ad-4de8-a2ac-342ce74f0108"
}