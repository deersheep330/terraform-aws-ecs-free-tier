output "redis_host" {
  description = "redis host"
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.address}"
  sensitive = true
}