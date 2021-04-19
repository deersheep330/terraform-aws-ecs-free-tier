terraform {
  backend "remote" {
    hostname = "app.terraform.io"
  }
}

provider "aws" {
  region = var.aws_region
}

