terraform {
  backend "s3" {
    bucket = "deerpark-terraform-state-prod"
    key = "network/terraform.tfstate"
  }
}

provider "aws" {}

// network-related

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "tf-prod-vpc"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tf-prod-internet-gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  
  vpc_id = aws_vpc.vpc.id

  // Note that the default route, mapping the VPC’s CIDR block to “local”, is created implicitly and cannot be specified.

  // 0.0.0.0/0, ::/0 - Means source can be any ip address, means from any system request is accepted
  // 0.0.0.0/0 represents ipv4
  // ::/0 represents ipv6.

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "tf-prod-public-route-table"
  }

}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "tf-prod-public-subnet"
  }
}

resource "aws_network_acl" "public_subnet_network_acl" {

  vpc_id = aws_vpc.vpc.id
  subnet_ids = [ aws_subnet.public_subnet.id ]

  // from_port: The start of port range
  // to_port: The end of port range

  // set from_port = 0 and to_port = 0
  // to allow all ports

  ingress = [ {
    action = "allow"
    cidr_block = "0.0.0.0/0"
    protocol = "-1"
    from_port = 0
    to_port = 0
    rule_no = 100
  } ]

  // the (*)DENY ALL rule is added automatically

  egress = [ {
    action = "allow"
    cidr_block = "0.0.0.0/0"
    protocol = "-1"
    from_port = 0
    to_port = 0
    rule_no = 100
  } ]

  // the (*)DENY ALL rule is added automatically

  tags = {
    Name = "tf-prod-public-subnet-network-acl"
  }

}

resource "aws_route_table_association" "route_table_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

// instance-related

resource "aws_security_group" "ecs_sg" {

  vpc_id = aws_vpc.vpc.id

  ingress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }, {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  } ]

  egress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = "-1"
  } ]

  tags = {
    Name = "tf-prod-ecs-sg"
  }

}

resource "aws_security_group" "rds_sg" {

  vpc_id = aws_vpc.vpc.id

  ingress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "for debug only, login mysql from local machine, should be removed later"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
  } ]

  egress = [ {
    cidr_blocks = [ "value" ]
    description = "value"
    from_port = 1
    ipv6_cidr_blocks = [ "value" ]
    prefix_list_ids = [ "value" ]
    protocol = "value"
    security_groups = [ "value" ]
    self = false
    to_port = 1
  } ]

}

resource "aws_security_group" "lb_sg" {

  vpc_id = aws_vpc.vpc.id

  ingress = [ {
    cidr_blocks = [ "value" ]
    description = "value"
    from_port = 1
    ipv6_cidr_blocks = [ "value" ]
    prefix_list_ids = [ "value" ]
    protocol = "value"
    security_groups = [ "value" ]
    self = false
    to_port = 1
  } ]

  egress = [ {
    cidr_blocks = [ "value" ]
    description = "value"
    from_port = 1
    ipv6_cidr_blocks = [ "value" ]
    prefix_list_ids = [ "value" ]
    protocol = "value"
    security_groups = [ "value" ]
    self = false
    to_port = 1
  } ]

}






