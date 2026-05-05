# =============================================================================
# Aurora dSQL - Outputs
# =============================================================================

output "cluster_endpoint" {
  description = "Aurora dSQL cluster endpoint"
  value       = aws_dsql_cluster.this.endpoint
}

output "cluster_id" {
  description = "Aurora dSQL cluster ID"
  value       = aws_dsql_cluster.this.id
}

output "auth_token" {
  description = "Aurora dSQL auth token for IAM authentication"
  value       = data.aws_dsql_token.this.token
  sensitive   = true
}
