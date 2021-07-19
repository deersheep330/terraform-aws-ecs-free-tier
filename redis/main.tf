// [1] subnet group for redis

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

  engine = "redis"
  node_type = "cache.t2.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis3.2"
  engine_version = "3.2.10"

  tags = {
    Name = "${var.name_prefix}-redis"
  }

}
