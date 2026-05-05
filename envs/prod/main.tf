# =============================================================================
# Main - EC2 + Nginx + LiteLLM + Aurora dSQL Architecture
# =============================================================================

# --- VPC ---
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
}

# --- Security Groups ---
module "security_groups" {
  source = "../../modules/security-groups"

  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# --- IAM ---
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
}

# --- Aurora dSQL ---
module "dsql" {
  source = "../../modules/dsql"

  project_name = var.project_name
  db_name      = var.db_name
}

# --- EC2 ---
module "ec2" {
  source = "../../modules/ec2"

  project_name         = var.project_name
  subnet_id            = module.vpc.public_subnet_ids[0]
  security_group_ids   = [module.security_groups.ec2_security_group_id]
  instance_profile_name = module.iam.instance_profile_name
  dsql_endpoint        = module.dsql.cluster_endpoint
  litellm_master_key   = var.litellm_master_key
}

# --- Elastic IP ---
resource "aws_eip" "this" {
  instance = module.ec2.instance_id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}
