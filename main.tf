terraform {
  backend "s3" {
    bucket = "deerpark-terraform-state"
    key = "terraform-aws-ecs-free-tier/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {}

/* block A: network related */

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

// [3] route table

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
    Name = "${var.name_prefix}-public-route-table"
  }

}

// [4] subnet

// e.g. us-east-2a, us-east-2b
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.name_prefix}-public-subnet"
  }
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

// for aws_db_subnet_group, we have to create at least two subnets
resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.name_prefix}-public-subnet-2"
  }
}

// [5] network acl

resource "aws_network_acl" "public_subnet_network_acl" {

  vpc_id = aws_vpc.vpc.id
  subnet_ids = [ aws_subnet.public_subnet.id ]

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

/* block B: instance related */

// [1] security group

resource "aws_security_group" "ecs_sg" {

  name = "${var.name_prefix}-ecs-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    Name = "${var.name_prefix}-ecs-sg"
  }

}

resource "aws_security_group" "rds_sg" {

  name = "${var.name_prefix}-rds-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "for debug only, login mysql from local machine, should be removed later"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
  }
  
  /*
  ingress {
    cidr_blocks = [ aws_vpc.vpc.cidr_block ]
    description = "only allow traffic from this vpc"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
  }
  */

  ingress {
    security_groups = [ aws_security_group.ecs_sg.id ]
    description = "only allow traffic from instances belong to ecs security group"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = "tcp"
  }

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }

}

// [2] database subnet group

resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.name_prefix}-db-subnet-group"
  subnet_ids = [ aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id ]
  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

// [3] rds

resource "aws_db_instance" "rds" {

  identifier = "${var.name_prefix}-rds"

  allocated_storage = 10
  engine = "mysql"
  engine_version = "8.0.20"
  instance_class = "db.t2.micro"
  name = "mydb" # db name
  username = "root"
  password = "adminadmin"

  publicly_accessible = true
  skip_final_snapshot = true

  enabled_cloudwatch_logs_exports = [ "error", "general", "slowquery" ]
  delete_automated_backups = false
  // Specifies whether or not to create this database from a snapshot.
  // This correlates to the snapshot ID you'd find in the RDS console.
  // snapshot_identifier = "rds:production-2015-06-26-06-05"

  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [ aws_security_group.rds_sg.id ]

  tags = {
    Name = "${var.name_prefix}-rds"
  }

}

// [4] ec2 autoscaling group

// step 1: create iam role

data "aws_iam_policy_document" "ecs_iam_policy_document" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "ecs_iam_role" {
  name = "${var.name_prefix}-ecs-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_iam_policy_document.json
}

// attach managed policy to the created role

resource "aws_iam_role_policy_attachment" "ecs_iam_role_policy_attachment_ecs" {
  role = aws_iam_role.ecs_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

// attach managed policy to the created role

resource "aws_iam_role_policy_attachment" "ecs_iam_role_policy_attachment_ssm" {
  role = aws_iam_role.ecs_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

// attach managed policy to the created role

resource "aws_iam_role_policy_attachment" "ecs_iam_role_policy_attachment_cw_agent" {
  role = aws_iam_role.ecs_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

// attach inline policy to the created role

resource "aws_iam_role_policy" "ecs_iam_role_policy_ssm" {
  role = aws_iam_role.ecs_iam_role.name
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameter"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

// Use an instance profile to pass an IAM role to an EC2 instance.

resource "aws_iam_instance_profile" "ecs_iam_instance_profile" {
  name = "${var.name_prefix}-ecs-iam-instance-profile"
  role = aws_iam_role.ecs_iam_role.name
  // waiting for others
  // https://stackoverflow.com/questions/36802681/terraform-having-timing-issues-launching-ec2-instance-with-instance-profile
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

// step 2: create autoscaling group

data "local_file" "cloudwatch_agent_config_file" {
  filename = "amazon-cloudwatch-agent.json"
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = "cloudwatch-agent-config"
  type  = "String"
  value = data.local_file.cloudwatch_agent_config_file.content
  overwrite = true
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

data "template_file" "userdata" {
  template = file("${path.module}/launch-configuration-userdata.sh.tpl")
  vars = {
    cloudwatch_agent_config = aws_ssm_parameter.cloudwatch_agent_config.name
    ecs_cluster_name = var.ecs_cluster_name
  }
}

resource "aws_launch_configuration" "ecs_launch_configuration" {
  name = "${var.name_prefix}-ecs-launch-configuration"
  image_id = "ami-09f644e1caad2d877"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs_iam_instance_profile.id

  lifecycle {
    create_before_destroy = false
  }

  security_groups = [ aws_security_group.ecs_sg.id ]
  associate_public_ip_address = true
  user_data = data.template_file.userdata.rendered

  key_name = "automation-aws"

  depends_on = [ aws_ssm_parameter.cloudwatch_agent_config ]
}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  name = "${var.name_prefix}-ecs-autoscaling-group"
  vpc_zone_identifier = [ aws_subnet.public_subnet.id ]
  launch_configuration = aws_launch_configuration.ecs_launch_configuration.name

  desired_capacity = 1
  min_size = 1
  max_size = 1

  tag {
    key = "Name"
    value = "${var.name_prefix}-autoscaled-ec2"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value = "${var.name_prefix}-ecs-autoscaling-group"
    propagate_at_launch = false
  }
}

// [5] ecs cluster

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

// [6] iam role for task definition use

// task role:

data "aws_iam_policy_document" "task_role_iam_policy_document" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "ecs-tasks.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "task_role_iam_role" {
  name = "${var.name_prefix}-task-role-iam-role"
  assume_role_policy = data.aws_iam_policy_document.task_role_iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "task_role_iam_role_policy_attachment" {
  role = aws_iam_role.task_role_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// task execution role

data "aws_iam_policy_document" "task_execution_role_iam_policy_document" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "ecs-tasks.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "task_execution_role_iam_role" {
  name = "${var.name_prefix}-task-execution-role-iam-role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_role_iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "task_execution_role_iam_role_policy_attachment" {
  role = aws_iam_role.task_execution_role_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// ecr

resource "aws_ecr_repository" "ecr_repositories" {

  count = length(var.ecr_repos)

  name = var.ecr_repos[count.index]
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
