# =============================================================================
# EC2 - Variables
# =============================================================================

variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs for the EC2 instance"
  type        = list(string)
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "dsql_endpoint" {
  description = "Aurora dSQL cluster endpoint"
  type        = string
}

variable "litellm_master_key" {
  description = "Master key for LiteLLM proxy"
  type        = string
  sensitive   = true
}
