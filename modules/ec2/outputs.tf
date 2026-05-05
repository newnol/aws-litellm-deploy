################################################################################
# EC2 Module Outputs
################################################################################

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.this.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address (static)"
  value       = aws_eip.this.public_ip
}

output "private_ip" {
  description = "EC2 instance private IP"
  value       = aws_instance.this.private_ip
}
