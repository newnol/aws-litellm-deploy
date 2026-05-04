variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "ecr_repository_url" {
  description = "ECR repository URL for container image"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ECS execution role ARN"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 1024
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 4000
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "container_environment" {
  description = "Container environment variables"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "container_secrets" {
  description = "Container secrets from SSM/Secrets Manager"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}
