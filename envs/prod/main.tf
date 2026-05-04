locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ============================================================
# VPC — Public/Private subnets, IGW, NAT
# ============================================================
module "vpc" {
  source = "../../modules/vpc"

  project_name      = var.project_name
  environment       = var.environment
  vpc_cidr          = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
}

# ============================================================
# Security Groups — ALB, ECS, RDS
# ============================================================
module "security_groups" {
  source = "../../modules/security-groups"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port
}

# ============================================================
# ECR — Docker image registry
# ============================================================
module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ============================================================
# Secrets Manager — DB credentials, API keys
# ============================================================
module "secrets" {
  source = "../../modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  db_username  = var.db_username
  db_name      = var.db_name
}

# ============================================================
# IAM — ECS execution + task roles
# ============================================================
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  secret_arns = [
    module.secrets.db_credentials_secret_arn,
    module.secrets.api_keys_secret_arn,
  ]
}

# ============================================================
# RDS — PostgreSQL database
# ============================================================
module "rds" {
  source = "../../modules/rds"

  project_name         = var.project_name
  environment          = var.environment
  private_subnet_ids   = module.vpc.private_subnet_ids
  rds_sg_id            = module.security_groups.rds_sg_id
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = module.secrets.db_password
}

# ============================================================
# ALB — Application Load Balancer
# ============================================================
module "alb" {
  source = "../../modules/alb"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  alb_sg_id            = module.security_groups.alb_sg_id
  container_port       = var.container_port
  acm_certificate_arn  = var.acm_certificate_arn
}

# ============================================================
# ECS — Fargate cluster + service
# ============================================================
module "ecs" {
  source = "../../modules/ecs"

  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  ecr_repository_url      = module.ecr.repository_url
  private_subnet_ids      = module.vpc.private_subnet_ids
  ecs_sg_id               = module.security_groups.ecs_sg_id
  target_group_arn        = module.alb.target_group_arn
  ecs_execution_role_arn  = module.iam.ecs_execution_role_arn
  ecs_task_role_arn       = module.iam.ecs_task_role_arn
  task_cpu                = var.task_cpu
  task_memory             = var.task_memory
  container_port          = var.container_port
  desired_count           = var.desired_count

  container_environment = [
    {
      name  = "DATABASE_URL"
      value = "postgresql://${var.db_username}:${module.secrets.db_password}@${module.rds.db_host}:${module.rds.db_port}/${var.db_name}"
    },
    {
      name  = "PORT"
      value = tostring(var.container_port)
    },
  ]

  container_secrets = [
    {
      name      = "LITELLM_MASTER_KEY"
      valueFrom = module.secrets.api_keys_secret_arn
    },
  ]
}
