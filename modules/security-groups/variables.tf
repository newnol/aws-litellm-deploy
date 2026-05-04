variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create security groups in"
  type        = string
}

variable "container_port" {
  description = "Container port for ECS tasks"
  type        = number
  default     = 4000
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}
