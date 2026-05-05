# =============================================================================
# IAM - Outputs
# =============================================================================

output "instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.this.name
}

output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.this.arn
}
