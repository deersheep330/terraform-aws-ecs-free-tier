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
