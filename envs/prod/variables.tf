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

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (~$32/month)"
  type        = bool
  default     = true
}

# ECS
variable "container_port" {
  description = "Container port"
  type        = number
  default     = 4000
}

variable "task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory (MB)"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of ECS tasks"
  type        = number
  default     = 1
}

# RDS
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "litellm"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "litellm"
}

# Cloudflare
variable "domain" {
  description = "Domain name (managed by Cloudflare)"
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain for the app"
  type        = string
  default     = "litellm"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (empty = HTTP only, use Cloudflare SSL)"
  type        = string
  default     = ""
}
