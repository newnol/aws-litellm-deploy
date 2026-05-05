locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ============================================================
# VPC — Public subnet only (no NAT needed for single EC2)
# ============================================================
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ============================================================
# Security Groups — EC2 only
# ============================================================
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# ============================================================
# IAM — EC2 instance role
# ============================================================
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# ============================================================
# Aurora dSQL — Serverless PostgreSQL (scale to zero)
# ============================================================
module "dsql" {
  source = "../../modules/dsql"

  project_name = var.project_name
  environment  = var.environment
}

# ============================================================
# EC2 — t3.micro with Docker Compose + Elastic IP
# ============================================================
module "ec2" {
  source = "../../modules/ec2"

  project_name       = var.project_name
  environment        = var.environment
  instance_type      = var.instance_type
  subnet_id          = module.vpc.public_subnet_ids[0]
  sg_id              = module.security_groups.ec2_sg_id
  key_name           = var.key_name
  instance_profile   = module.iam.instance_profile_name
  litellm_master_key = var.litellm_master_key
  litellm_salt_key   = var.litellm_salt_key
  dsql_endpoint      = module.dsql.cluster_endpoint
}
