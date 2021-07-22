variable "name_prefix" {
  description = "Name prefix of each resources"
  type = string
}

variable "vpc" {
  description = "vpc generated from vpc module"
}

variable "subnets" {
  description = "subnets generated from vpc module"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster to be created"
  type = string
}

variable "certificate_arn" {
  description = "the aws acm certificate arn created from AWS Certificate Manager"
  type = string
}

variable "domain_name" {
  description = "the domain name you purchased should be registered as a route 53 hosted zone"
  type = string
}

variable "subdomain_url" {
  description = "the subdomain url you'd like redirect to application load banacer"
  type = string
}
