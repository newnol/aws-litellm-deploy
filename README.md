# AWS LiteLLM Deploy

Production-ready Terraform deployment of [LiteLLM Proxy](https://docs.litellm.ai/) on AWS using EC2 + Nginx + Aurora dSQL.

## Architecture

```
Internet
  |
  v
[Elastic IP]
  |
  v
[EC2 Instance]
  ├── Nginx (reverse proxy, port 80 → 4000)
  ├── Docker Compose
  │   └── LiteLLM Proxy (port 4000)
  └── Aurora dSQL (managed PostgreSQL)
```

### Components

- **VPC** – Custom VPC with public subnets
- **EC2** – Amazon Linux 2023 instance running LiteLLM via Docker Compose
- **Nginx** – Reverse proxy on port 80 forwarding to LiteLLM on port 4000
- **Aurora dSQL** – Serverless PostgreSQL-compatible database for LiteLLM
- **IAM** – Instance profile with SSM access and Aurora dSQL auth
- **Security Groups** – Controlled access for EC2 (HTTP, SSH, LiteLLM port)

## Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.5
- AWS CLI configured with appropriate credentials
- An AWS account with permissions for EC2, VPC, Aurora dSQL, IAM, and SSM

## Quick Start

```bash
# 1. Copy and edit the tfvars file
cp envs/prod/terraform.tfvars.example envs/prod/terraform.tfvars
vi envs/prod/terraform.tfvars

# 2. Initialize and deploy
./deploy.sh init
./deploy.sh plan
./deploy.sh apply

# 3. SSH and check
./deploy.sh ssh
./deploy.sh status
```

## Configuration

Edit `envs/prod/terraform.tfvars` to customize:

- `aws_region` – AWS region (default: us-east-1)
- `project_name` – Name prefix for resources
- `db_name` – Aurora dSQL database name
- `allowed_ssh_cidr` – CIDR block allowed to SSH

## Commands

| Command | Description |
|---------|-------------|
| `./deploy.sh init` | Initialize Terraform |
| `./deploy.sh plan` | Create Terraform plan |
| `./deploy.sh apply` | Deploy infrastructure |
| `./deploy.sh destroy` | Destroy all infrastructure |
| `./deploy.sh ssh` | SSH into EC2 instance |
| `./deploy.sh status` | Check deployment status |
| `./deploy.sh logs` | View container logs |
| `./deploy.sh restart` | Restart LiteLLM containers |

Or use `make`:

```bash
make init
make plan
make apply
```

## Costs

Estimated monthly cost (us-east-1):

- EC2 (t3.micro): ~$8/month
- Aurora dSQL: Pay-per-request (serverless)
- Elastic IP: Free (while attached)
- VPC: Free

**Total: ~$8/month + Aurora dSQL usage**

## Security Notes

- SSH access is restricted by `allowed_ssh_cidr`
- Nginx runs on port 80 (consider adding TLS termination)
- Aurora dSQL uses IAM authentication
- EC2 instance has SSM access for management
