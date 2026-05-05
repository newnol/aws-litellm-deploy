################################################################################
# Aurora dSQL Module Variables
################################################################################

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_identifier" {
  description = "Cluster identifier for Aurora dSQL"
  type        = string
}
