variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "secret_arns" {
  description = "List of secret ARNs to grant access to"
  type        = list(string)
}
