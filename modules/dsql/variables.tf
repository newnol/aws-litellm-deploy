# =============================================================================
# Aurora dSQL - Variables
# =============================================================================

variable "project_name" {
  description = "Project name (used as prefix for resources)"
  type        = string
}

variable "db_name" {
  description = "Aurora dSQL database name"
  type        = string
  default     = "litellm"
}
