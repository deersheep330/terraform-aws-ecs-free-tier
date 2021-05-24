// [1] vpc

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

// [2] internet gateway

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name_prefix}-internet-gateway"
  }
}

// [3] subnet

// e.g. us-east-2a, us-east-2b, us-east-2c
data "aws_availability_zones" "available" {
  state = "available"
}

// create 3 subnets for 3 availiable zones
resource "aws_subnet" "subnets" {

  count = length(data.aws_availability_zones.available.names)

  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.name_prefix}-subnet-${count.index}"
  }
}

// [4] route table and network acl for public subnet

resource "aws_route_table" "public_subnet_route_table" {
  
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
    Name = "${var.name_prefix}-public-subnet-route-table"
  }

}

resource "aws_route_table_association" "route_table_association" {
  subnet_id = aws_subnet.subnets[0].id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

resource "aws_network_acl" "public_subnet_network_acl" {

  vpc_id = aws_vpc.vpc.id
  subnet_ids = [ aws_subnet.subnets[0].id ]

  // from_port: The start of port range
  // to_port: The end of port range

  // set from_port = 0 and to_port = 0
  // to allow all ports

  ingress {
    action = "allow"
    cidr_block = "0.0.0.0/0"
    protocol = "-1"
    from_port = 0
    to_port = 0
    rule_no = 100
  }

  // the (*)DENY ALL rule is added automatically

  egress {
    action = "allow"
    cidr_block = "0.0.0.0/0"
    protocol = "-1"
    from_port = 0
    to_port = 0
    rule_no = 100
  }

  // the (*)DENY ALL rule is added automatically

  tags = {
    Name = "${var.name_prefix}-public-subnet-network-acl"
  }

}





