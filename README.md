# 🚀 aws-litellm-deploy

Production-ready AWS infrastructure for deploying containerized applications using **Terraform IaC**.

> Pattern: Cloudflare (DNS + SSL) → ALB → ECS Fargate → RDS PostgreSQL

## Architecture

```
Internet → Cloudflare (DNS + SSL) → ALB (HTTP:80) → ECS Fargate → RDS PostgreSQL
                                                              ↕
                                                     Secrets Manager
```

**Components:**
- **VPC** — Public/private subnets across 2 AZs, IGW, NAT Gateway
- **ALB** — Application Load Balancer with health checks
- **ECS Fargate** — Serverless container hosting
- **RDS PostgreSQL** — Managed database (encrypted, auto-backup)
- **ECR** — Docker image registry with lifecycle policy
- **Secrets Manager** — DB credentials + API keys
- **IAM** — Least-privilege roles for ECS tasks

## Project Structure

```
aws-litellm-deploy/
├── deploy.sh                    # Unified deploy script
├── Makefile                     # Make shortcuts
├── Dockerfile                   # Container image
├── modules/                     # Reusable Terraform modules
│   ├── vpc/                     # VPC, subnets, IGW, NAT
│   ├── security-groups/         # ALB, ECS, RDS security groups
│   ├── ecr/                     # Docker registry
│   ├── secrets/                 # Secrets Manager
│   ├── iam/                     # Least-privilege IAM roles
│   ├── rds/                     # PostgreSQL database
│   ├── alb/                     # Application Load Balancer
│   └── ecs/                     # Fargate cluster + service
└── envs/
    ├── prod/                    # Production environment
    │   ├── main.tf              # Module composition
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── provider.tf
    │   └── terraform.tfvars.example
    └── dev/                     # (optional) Development environment
```

## Quick Start

### Prerequisites
- [Terraform](https://terraform.io/downloads) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- [Docker](https://docs.docker.com/get-docker/) (for building images)

### 1. Setup

```bash
git clone https://github.com/newnol/aws-litellm-deploy.git
cd aws-litellm-deploy

# Copy and customize variables
cp envs/prod/terraform.tfvars.example envs/prod/terraform.tfvars
vim envs/prod/terraform.tfvars
```

### 2. Deploy Infrastructure

```bash
# Initialize
make init

# Preview changes
make plan

# Apply
make apply

# Or full deploy (init → plan → apply)
make deploy
```

### 3. Deploy Application

```bash
# Build and push Docker image
make build

# Force new ECS deployment
make force-deploy

# Check status
make status

# View logs
make logs
```

### 4. Destroy

```bash
make destroy
# Type environment name to confirm
```

## Available Commands

| Command | Description |
|---------|-------------|
| `make init` | Initialize Terraform |
| `make plan` | Plan changes |
| `make apply` | Apply saved plan |
| `make deploy` | Full deploy |
| `make build` | Build & push Docker image |
| `make force-deploy` | Force new ECS deployment |
| `make logs` | Tail CloudWatch logs |
| `make status` | Show deployment status |
| `make destroy` | Destroy all resources |
| `make fmt` | Format Terraform files |
| `make validate` | Validate config |

## Cost Estimate

| Component | Monthly Cost |
|-----------|-------------|
| ECS Fargate (0.5 vCPU, 1GB) | ~$15 |
| RDS db.t3.micro | Free tier (750h) |
| ALB | Free tier (750h) |
| NAT Gateway | ~$32 |
| ECR (storage) | ~$0.10 |
| Secrets Manager | ~$0.40 |
| **Total** | **~$47/month** |

**Save $32/month:** Set `enable_nat_gateway = false` in terraform.tfvars (ECS tasks lose internet access).

## Cloudflare Integration

1. Add CNAME record in Cloudflare:
   - **Name:** `litellm` (or your subdomain)
   - **Target:** ALB DNS name (from `terraform output alb_dns_name`)
   - **Proxy:** ON (orange cloud)

2. Cloudflare settings:
   - SSL mode: **Full** (not Flexible)
   - Always Use HTTPS: **ON**

## Security

- **Security Groups:** ALB → ECS → RDS (layered access)
- **IAM:** Least-privilege roles for ECS tasks
- **Secrets:** Auto-generated DB password, stored in Secrets Manager
- **Encryption:** RDS storage encrypted at rest
- **Network:** Private subnets for ECS + RDS, no public access

## CV Description

```
LiteLLM on AWS — Production Infrastructure (Terraform IaC)
• Deployed LiteLLM proxy on AWS ECS Fargate with modular Terraform (8 modules)
• Architected: VPC (public/private subnets), ALB, ECS Fargate, RDS PostgreSQL
• Implemented least-privilege IAM, Secrets Manager, VPC security groups
• Cloudflare DNS + SSL proxy for secure public endpoint
• Automated: build → push ECR → deploy ECS (single script)
• Tech: AWS (ECS, RDS, ALB, ECR, IAM, VPC, Secrets Manager, CloudWatch),
  Terraform, Docker, PostgreSQL, Cloudflare
```

## License

MIT
