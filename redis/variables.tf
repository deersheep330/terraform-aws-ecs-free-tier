variable "name_prefix" {
  description = "Name prefix of each resources"
  type = string
}

variable "subnets" {
  description = "subnets generated from vpc module"
}
