variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB security group ID"
  type        = string
}

variable "container_port" {
  description = "Container port for target group"
  type        = number
  default     = 4000
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/health"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (empty to skip HTTPS)"
  type        = string
  default     = ""
}
