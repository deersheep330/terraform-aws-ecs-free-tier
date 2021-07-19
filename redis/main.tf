// [1] security group for redis

resource "aws_security_group" "redis_sg" {

  name = "${var.name_prefix}-redis-sg"
  vpc_id = var.vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "for debug only, login redis from local machine, should be removed later"
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
  }
  
  
  ingress {
    cidr_blocks = [ var.vpc.cidr_block ]
    description = "only allow traffic from this vpc"
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = "tcp"
  }

  tags = {
    Name = "${var.name_prefix}-redis-sg"
  }

}

// [2] subnet group for redis

resource "aws_elasticache_subnet_group" "redis_subnet_group" {

  name = "${var.name_prefix}-redis-subnet-group"
  subnet_ids = "${var.subnets.*.id}"
  tags = {
    Name = "${var.name_prefix}-redis-subnet-group"
  }

}

// [2] redis instance

resource "aws_elasticache_cluster" "redis" {

  cluster_id = "${var.name_prefix}-redis"

  security_group_ids = [ aws_security_group.redis_sg.id ]
  subnet_group_name = aws_elasticache_subnet_group.redis_subnet_group.name

  engine = "redis"
  node_type = "cache.t2.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis3.2"
  engine_version = "3.2.10"

  tags = {
    Name = "${var.name_prefix}-redis"
  }

}
