# =============================================================================
# EC2 - Outputs
# =============================================================================

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.this.private_ip
}
