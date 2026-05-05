# =============================================================================
# Outputs
# =============================================================================

output "elastic_ip" {
  description = "Elastic IP address of the EC2 instance"
  value       = aws_eip.this.public_ip
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.project_name}.pem ec2-user@${aws_eip.this.public_ip}"
}

output "litellm_url" {
  description = "URL to access LiteLLM proxy"
  value       = "http://${aws_eip.this.public_ip}:4000"
}

output "dsql_endpoint" {
  description = "Aurora dSQL cluster endpoint"
  value       = module.dsql.cluster_endpoint
}

output "dsql_token" {
  description = "Aurora dSQL auth token (use with IAM auth)"
  value       = module.dsql.auth_token
  sensitive   = true
}
