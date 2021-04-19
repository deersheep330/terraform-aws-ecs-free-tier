terraform {
  backend "s3" {
    bucket = "deerpark-terraform-state-prod"
    key = "network/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}
