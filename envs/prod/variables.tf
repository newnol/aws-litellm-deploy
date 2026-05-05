# =============================================================================
# Variables
# =============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
  default     = "litellm"
}

variable "db_name" {
  description = "Aurora dSQL database name"
  type        = string
  default     = "litellm"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the EC2 instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "litellm_master_key" {
  description = "Master key for LiteLLM proxy"
  type        = string
  default     = "sk-litellm-master"
  sensitive   = true
}
