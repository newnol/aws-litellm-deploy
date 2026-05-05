# =============================================================================
# Security Groups - Variables
# =============================================================================

variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the EC2 instance"
  type        = string
}
