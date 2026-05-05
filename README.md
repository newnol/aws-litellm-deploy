# 🚀 aws-litellm-deploy

Production-ready AWS infrastructure for deploying **LiteLLM Proxy** using **Terraform IaC**.

> **Architecture:** Cloudflare (DNS + SSL) → EC2 + Docker Compose (Nginx + LiteLLM) → Aurora dSQL

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    AWS Cloud                         │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  VPC (10.0.0.0/16)                           │   │
│  │                                               │   │
│  │  ┌─────────────────────────────────────────┐ │   │
│  │  │  Public Subnet (10.0.1.0/24)            │ │   │
│  │  │                                         │ │   │
│  │  │  ┌─────────────────────────────────┐    │ │   │
│  │  │  │  EC2 t3.micro                   │    │ │   │
│  │  │  │  ┌──────────────────────────┐   │    │ │   │
│  │  │  │  │  Docker Compose          │   │    │ │   │
│  │  │  │  │  ┌──────────────────┐    │   │    │ │   │
│  │  │  │  │  │  Nginx (:80)     │    │   │    │ │   │
│  │  │  │  │  │  ↕               │    │   │    │ │   │
│  │  │  │  │  │  LiteLLM (:4000) │    │   │    │ │   │
│  │  │  │  │  └──────────────────┘    │   │    │ │   │
│  │  │  │  └──────────────────────────┘   │    │ │   │
│  │  │  │  Elastic IP (static)            │    │ │   │
│  │  │  └─────────────────────────────────┘    │ │   │
│  │  └─────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  Aurora dSQL (Serverless PostgreSQL)          │   │
│  │  - Scale to zero                              │   │
│  │  - Pay per query                              │   │
│  │  - PostgreSQL wire protocol                   │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘

Internet → Cloudflare (DNS + SSL) → EC2 (Elastic IP) → Nginx (:80) → LiteLLM (:4000) → Aurora dSQL
```

**Components:**
- **VPC** — Simple VPC with public subnet, Internet Gateway (no NAT needed)
- **EC2 t3.micro** — Free Tier eligible, running Docker Compose with Nginx + LiteLLM
- **Nginx** — Reverse proxy with rate limiting, security headers, and load balancing ready
- **LiteLLM** — LLM proxy on port 4000 (internal only, exposed via Nginx)
- **Aurora dSQL** — Serverless PostgreSQL, scale to zero, pay per query
- **Elastic IP** — Static public IP for consistent access
- **IAM** — Least-privilege roles for EC2 (CloudWatch, SSM)
- **Security Groups** — SSH + HTTP (80) + HTTPS (443) access

## Project Structure

```
aws-litellm-deploy/
├── deploy.sh                    # Unified deploy script
├── Makefile                     # Make shortcuts
├── Dockerfile                   # Container image
├── docker-compose.yml           # Docker Compose for Nginx + LiteLLM
├── nginx/
│   └── nginx.conf               # Nginx reverse proxy config
├── modules/                     # Reusable Terraform modules
│   ├── vpc/                     # VPC, public subnet, IGW
│   ├── security-groups/         # EC2 security group
│   ├── ec2/                     # EC2 instance + Elastic IP
│   ├── dsql/                    # Aurora dSQL cluster
│   └── iam/                     # EC2 IAM roles
└── envs/
    └── prod/                    # Production environment
        ├── main.tf              # Module composition
        ├── variables.tf
        ├── outputs.tf
        ├── provider.tf
        └── terraform.tfvars.example
```

## Quick Start

### Prerequisites
- [Terraform](https://terraform.io/downloads) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- SSH key pair in AWS (for EC2 access)

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

### 3. Verify & Use

```bash
# Check status
make status

# SSH into instance
make ssh

# View Docker logs
make logs

# Access LiteLLM via Nginx (recommended)
curl http://<ELASTIC_IP>/health/readiness

# Direct LiteLLM access (port 4000, internal)
curl http://<ELASTIC_IP>:4000/health/readiness
```

### 4. Destroy

```bash
make destroy
# Type environment name to confirm
```

## Available Commands

- `make init` — Initialize Terraform
- `make plan` — Plan changes
- `make apply` — Apply saved plan
- `make deploy` — Full deploy (init → plan → apply)
- `make status` — Show deployment status
- `make logs` — Tail Docker logs via SSH
- `make ssh` — SSH into EC2 instance
- `make destroy` — Destroy all resources
- `make fmt` — Format Terraform files
- `make validate` — Validate config

## Cost Estimate

- **EC2 t3.micro** — Free tier (750h/month for 12 months)
- **Aurora dSQL** — Pay per query, scale to zero (~$0-5/month)
- **Elastic IP** — Free when attached to running instance
- **VPC** — Free (no NAT Gateway needed)
- **Total** — **~$0-5/month** (Free Tier eligible)

After Free Tier expires:
- **EC2 t3.micro** — ~$8/month
- **Aurora dSQL** — ~$0-5/month
- **Total** — **~$8-13/month**

## Cloudflare Integration

1. Add **A record** in Cloudflare:
   - **Name:** `litellm` (or your subdomain)
   - **Target:** Elastic IP (from `terraform output elastic_ip`)
   - **Proxy:** ON (orange cloud)

2. Cloudflare settings:
   - SSL mode: **Full** (not Flexible)
   - Always Use HTTPS: **ON**

## Environment Variables

The EC2 instance uses these environment variables (set in `terraform.tfvars`):

- `LITELLM_MASTER_KEY` — Master API key for LiteLLM
- `LITELLM_SALT_KEY` — Salt key for encryption

Database connection is automatically configured via dSQL.

## Security

- **Security Group:** SSH (22) + HTTP (80) + HTTPS (443) access
- **Nginx:** Rate limiting (30 req/s), security headers, reverse proxy
- **IAM:** Least-privilege roles for EC2 instance
- **dSQL:** IAM-based authentication (no password in config)
- **Network:** Public subnet with controlled access via security group
- **Elastic IP:** Consistent IP for firewall rules

## CV Description

```
LiteLLM on AWS — Production Infrastructure (Terraform IaC)
• Deployed LiteLLM proxy on AWS EC2 with Docker Compose using modular Terraform (5 modules)
• Architected: VPC (public subnet), EC2 t3.micro, Aurora dSQL (serverless PostgreSQL)
• Added Nginx reverse proxy with rate limiting, security headers, and load balancing ready
• Implemented Elastic IP for static access, IAM least-privilege roles
• Cloudflare DNS + SSL proxy for secure public endpoint
• Automated: terraform init → plan → apply (single script)
• Cost optimized: ~$0-5/month on AWS Free Tier
• Tech: AWS (EC2, Aurora dSQL, VPC, IAM, Elastic IP), Terraform, Docker, Nginx, PostgreSQL, Cloudflare
```

## License

MIT
