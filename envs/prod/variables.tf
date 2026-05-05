variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "litellm"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

# VPC
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# EC2
variable "instance_type" {
  description = "EC2 instance type (t3.micro for Free Tier)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
}

# LiteLLM
variable "litellm_master_key" {
  description = "LiteLLM master API key"
  type        = string
  sensitive   = true
}

variable "litellm_salt_key" {
  description = "LiteLLM salt key for hashing"
  type        = string
  sensitive   = true
}
