################################################################################
# EC2 Module Variables
################################################################################

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "sg_id" {
  description = "Security group ID for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "litellm_master_key" {
  description = "LiteLLM master API key"
  type        = string
  sensitive   = true
}

variable "litellm_salt_key" {
  description = "LiteLLM salt key for encryption"
  type        = string
  sensitive   = true
}

variable "dsql_endpoint" {
  description = "Aurora dSQL cluster endpoint"
  type        = string
}
