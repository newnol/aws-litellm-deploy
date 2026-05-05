################################################################################
# Aurora dSQL Module Outputs
################################################################################

output "cluster_endpoint" {
  description = "Aurora dSQL cluster endpoint"
  value       = aws_dsql_cluster.this.endpoint
}

output "cluster_arn" {
  description = "Aurora dSQL cluster ARN"
  value       = aws_dsql_cluster.this.arn
}

output "cluster_id" {
  description = "Aurora dSQL cluster ID"
  value       = aws_dsql_cluster.this.id
}
